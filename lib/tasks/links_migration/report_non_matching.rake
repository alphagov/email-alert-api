require "tasks/links_migration/link_migrator"

namespace :links_migration do
  desc "Populate topics in empty links on SubscriberList using the tags field"
  task report_non_matching: [:environment] do
    Tasks::LinksMigration::LinkMigrator.new.report_non_matching_subscriber_lists
  end
end
