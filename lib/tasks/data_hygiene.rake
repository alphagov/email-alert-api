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

desc "Sync topic mappings to govdelivery, DO NOT USE IN PRODUCTION"
task sync_govdelivery_topic_mappings: :environment do
  unless ENV["ALLOW_GOVDELIVERY_SYNC"] == "allow"
    puts "Syncing GovDelivery has not been configured for this environment."
    puts "Running this against production GovDelivery would be a really bad idea."
    puts "If you're sure you want to run this, export ALLOW_GOVDELIVERY_SYNC='allow'"

    exit
  end

  unless EmailAlertAPI.config.gov_delivery[:hostname] == "stage-api.govdelivery.com"
    puts "It looks like you're running this sync with a non-staging GovDelivery configuration."
    puts "Running this against production GovDelivery would be a really bad idea."
    puts "If the GovDelivery staging hostname has changed, please update this applciation and try again."

    exit
  end

  puts "Fetching topics.."
  topics = Services.gov_delivery.fetch_topics["topics"]

  if topics.blank?
    puts "No topics found in GovDelivery."
  else
    puts "Deleting all remote topics.."
    topics.each do |topic|
      puts "-- Deleting #{topic["name"]} (#{topic["code"]})"
      Services.gov_delivery.delete_topic(topic["code"])
    end

    # GovDelivery delete topics asynchronously and/or are only eventually
    # consistent on deletes.  We have to wait until all the deletes take effect
    # or we'll get conflicts when trying to recreate them.
    attempts = 0
    while Array(Services.gov_delivery.fetch_topics["topics"]).count > 0
      sleep 1

      if attempts >= 15
        puts "Attempted to delete all topics and it doesn't seem to have worked."
        puts "Trying again may work."
        exit
      else
        attempts += 1
      end
    end
  end

  puts "Creating remote topics to match the #{SubscriberList.count} local topics.."
  created = {}
  SubscriberList.find_each do |list|
    next if created.has_key?(list.gov_delivery_id)

    title = list.title || "MISSING TITLE #{list.gov_delivery_id}"
    puts "-- Creating #{title} (#{list.gov_delivery_id}) in GovDelivery"
    Services.gov_delivery.create_topic(title, list.gov_delivery_id)

    created[list.gov_delivery_id] = true
  end
end
