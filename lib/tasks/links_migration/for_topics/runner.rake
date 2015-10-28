require "tasks/links_migration/topic_link_migrator"

namespace :links_migration do
  namespace :for_topics do

    desc "Print out a report of topic subscriber lists with no obvious content ID match in the content store"
    task report_non_matching: [:environment] do
      Tasks::LinksMigration::LinkMigrator.new.report_non_matching_subscriber_lists
    end

    desc "Populate topics in empty links on SubscriberList using the tags field"
    task populate_topic_links: [:environment] do
      Tasks::LinksMigration::LinkMigrator.new.populate_topic_links
    end

  end
end
