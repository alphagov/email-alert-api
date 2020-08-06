namespace :clean do
  desc "Remove SubscriberLists with no subscriptions"
  task remove_empty_subscriberlists: :environment do
    dry_run = ENV["DRY_RUN"] != "no"
    cleaner = Clean::EmptySubscriberLists.new
    cleaner.remove_empty_subscriberlists(dry_run: dry_run)
  end

  desc <<~DESC
    Remove subscribers with multiple emails that failed to send

    Usage: rake clean:invalid_subscribers[/path/to/sent_csv,/path_to_failed_csv]

    Run the following queries on Athena:

    select subscriber_id, COUNT(id) as count
      from email_archive
      where sent=false and subscriber_id is not null
      group by subscriber_id

    and

     select subscriber_id, COUNT(id) as count
      from email_archive
      where sent=true and subscriber_id is not null
      group by subscriber_id

    Download the results to two CSV files and use the respective paths as the parameters.

    Set the environment variable DRY_RUN=false if the subscribers should be deactivated.
  DESC
  task :invalid_subscribers, %i[sent_csv failed_csv] => :environment do |_t, args|
    dry_run = ENV["DRY_RUN"] != "no"
    cleaner = Clean::InvalidSubscribers.new(
      sent_csv: File.open(args[:sent_csv]),
      failed_csv: File.open(args[:failed_csv]),
    )
    cleaner.deactivate_subscribers(dry_run: dry_run)
  end
end
