namespace :clean do
  desc "Remove SubscriberLists with no subscriptions"
  task remove_empty_subscriberlists: :environment do
    dry_run = ENV["DRY_RUN"] != "no"
    cleaner = Clean::EmptySubscriberLists.new
    cleaner.remove_empty_subscriberlists(dry_run: dry_run)
  end
end
