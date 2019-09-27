namespace :clean do
  desc "Remove SubscriberLists with no subscriptions"
  task remove_empty_subscriberlists: :environment do
    dry_run = is_dry_run?
    cleaner = Clean::EmptySubscriberLists.new
    cleaner.remove_empty_subscriberlists(dry_run: dry_run)
  end

  def is_dry_run?
    dry = ENV["DRY_RUN"] != "no"
    puts "Warning: Running in DRY_RUN mode. Use DRY_RUN=no to run live." if dry
    dry
  end
end
