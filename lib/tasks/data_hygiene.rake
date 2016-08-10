desc "Create duplicate record for new tags"
task duplicate_record_for_tag: :environment do
  require "data_hygiene/tag_changer"

  from_topic_tag = ENV['FROM_TOPIC_TAG']
  to_topic_tag = ENV['TO_TOPIC_TAG']

  if from_topic_tag.blank?
    $stderr.puts "A from_topic_tag must be supplied"
    exit 1
  elsif to_topic_tag.blank?
    $stderr.puts "A to_topic_tag must be supplied"
    exit 1
  end

  puts 'STARTING'
  DataHygiene::TagChanger.new(from_topic_tag: from_topic_tag, to_topic_tag: to_topic_tag).update_records_tags
  puts 'FINISHED'
end

desc "Sync topic mappings from govdelivery, DO NOT USE IN PRODUCTION"
task sync_topic_mappings: :environment do
  puts "Fetching topics.."
  topics = Services.gov_delivery.fetch_topics["topics"]

  if topics.blank?
    puts "No topics found."
    exit
  end

  gov_delivery_ids = []

  puts "Updating local topics.."
  topics.each do |topic|
    list = SubscriberList.find_by(title: topic["name"])

    if list
      puts "-- Updating #{topic["name"]} (#{list.gov_delivery_id} -> #{topic["code"]})"
      list.update_columns(gov_delivery_id: topic["code"])
    else
      puts "-- Missing local copy of #{topic["name"]} (#{topic["code"]})"
    end

    gov_delivery_ids << topic["code"]
  end

  extra_lists = SubscriberList.where.not(gov_delivery_id: gov_delivery_ids)
  puts "Deleting #{extra_lists.count} local subscriber lists not found in govdelivery.."
  extra_lists.delete_all
end

desc "Delete topics from govdelivery where title starts with string, DO NOT USE IN PRODUCTION"
task :delete_matching_topics, [:string] => :environment do |_, args|
  string = args[:string]

  if string.blank?
    puts "Provide a string to match"
    puts "rake delete_matching_topics['string to match']"
    exit
  end

  puts "Fetching topics.."
  topics = Services.gov_delivery.fetch_topics["topics"]

  if topics.blank?
    puts "No topics found."
    exit
  end

  topics.each do |topic|
    if topic["name"].starts_with?(string)
      puts "Deleting #{topic["name"]} (#{topic["code"]})"
      Services.gov_delivery.delete_topic(topic["code"])
    end
  end
end
