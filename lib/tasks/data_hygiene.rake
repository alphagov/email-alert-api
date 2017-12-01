desc "Delete subscriber lists without subscribers and ones which don't exist in GovDelivery"
task delete_unneeded_topics: :environment do
  require "data_hygiene/delete_unneeded_topics"

  DataHygiene::DeleteUnneededTopics.new.call
  puts 'FINISHED'
end

desc "Sync topic mappings to govdelivery, DO NOT USE IN PRODUCTION"
task sync_govdelivery_topic_mappings: :environment do
  require "data_hygiene/data_sync"

  DataHygiene::DataSync.new.run
end
