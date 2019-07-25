namespace :clean do
  desc "List invalid SubscriberLists that will not deliver emails"
  task :report_invalid_subscriber_lists, [:id] => :environment do |_t, _args|
    lists = Clean::InvalidSubscriberLists.new.lists
    num_lists = lists.count
    puts "Found #{num_lists} #{'lists'.pluralize(num_lists)} that are invalid"
  end

  desc "
    Subscribe people that have subscriptions to invalid lists to valid lists

    * Looks up all invalid SubscriberLists
    * For each invalid SubscriberList, creates a valid list
    * Subscribes subscribers of invalid list to the valid list
    * Does not delete any bad lists or subscriptions

    By default, this will not create anything. If you would like it to, use
    DRY_RUN=no. E.g. `DRY_RUN=no bundle exec rake clean:migrate_subscriptions_to_valid_lists`
  "
  task :migrate_subscriptions_to_valid_lists, [:id] => :environment do |_t, _args|
    dry_run = is_dry_run?
    cleaner = Clean::InvalidSubscriberLists.new
    lists = cleaner.lists
    num_lists = lists.count
    puts "Found #{num_lists} #{'lists'.pluralize(num_lists)} that are invalid"

    lists.each { |from_list|
      new_list = cleaner.valid_list(from_list, dry_run: dry_run)
      cleaner.copy_subscribers(from_list, new_list, dry_run: dry_run)
    }
  end

  desc "Deactivate subcriptions to invalid SubscriberLists"
  task :deactivate_invalid_subscriptions, [:id] => :environment do |_t, _args|
    dry_run = is_dry_run?
    cleaner = Clean::InvalidSubscriberLists.new
    cleaner.deactivate_invalid_subscriptions(dry_run: dry_run)
  end

  desc "Remove SubscriberLists with no subscriptions"
  task remove_empty_subscriberlists: :environment do
    dry_run = is_dry_run?
    cleaner = Clean::EmptySubscriberLists.new
    cleaner.remove_empty_subscriberlists(dry_run: dry_run)
  end

  desc "Destroys SubscriberLists that don't pass validations and don't have active subscriptions"
  task delete_invalid_subscriber_lists: :environment do
    dry_run = is_dry_run?
    cleaner = Clean::InvalidSubscriberLists.new
    cleaner.destroy_invalid_subscriber_lists(dry_run: dry_run)
  end

  def is_dry_run?
    dry = ENV["DRY_RUN"] != 'no'
    puts "Warning: Running in DRY_RUN mode. Use DRY_RUN=no to run live." if dry
    dry
  end
end
