require "tasks/links_migration/link_migrator"

namespace :links_migration do
  desc "Remove Subscriber Lists with no matching content ID in Content Store"
  task destroy_outdated_subscriber_lists: [:environment] do
    Tasks::LinksMigration::LinkMigrator.new.destroy_non_matching_subscriber_lists
  end
end
