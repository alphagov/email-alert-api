require "tasks/links_migration/link_migrator"

namespace :links_migration do
  desc "Populate topics in empty links on SubscriberList using the tags field"
  task populate_topic_links: [:environment] do
    Tasks::LinksMigration::LinkMigrator.new.populate_topic_links
  end
end
