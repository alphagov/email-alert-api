desc "Delete subscriber lists without subscribers"
task delete_topics_without_subscribers: :environment do
  require "data_hygiene/delete_topics_without_subscribers"

  DataHygiene::DeleteTopicsWithoutSubscribers.new.call
  puts 'FINISHED'
end

desc "Create duplicate record for new tags"
task duplicate_record_for_tag: :environment do
  require "data_hygiene/tag_changer"

  from_topic_tag = ENV['FROM_TOPIC_TAG']
  to_topic_tag = ENV['TO_TOPIC_TAG']

  if from_topic_tag.blank?
    $stderr.puts "A from_topic_tag must be supplied"
    abort
  elsif to_topic_tag.blank?
    $stderr.puts "A to_topic_tag must be supplied"
    abort
  end

  puts 'STARTING'
  DataHygiene::TagChanger.new(from_topic_tag: from_topic_tag, to_topic_tag: to_topic_tag).update_records_tags
  puts 'FINISHED'
end

desc "Sync topic mappings to govdelivery, DO NOT USE IN PRODUCTION"
task sync_govdelivery_topic_mappings: :environment do
  require "data_hygiene/data_sync"

  DataHygiene::DataSync.new.run
end
