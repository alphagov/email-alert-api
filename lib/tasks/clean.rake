namespace :clean do
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

  desc "Migrate subscribers to working specialist finder lists"
  task migrate_specialist_subscribers: :environment do
    dry_run = is_dry_run?
    cleaner = Clean::MigrateSpecialistSubscriberLists.new
    cleaner.migrate_subscribers_to_working_lists(dry_run: dry_run)
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
    dry_run = is_dry_run?
    cleaner = Clean::InvalidSubscribers.new(sent_csv: File.open(args[:sent_csv]),
                                            failed_csv: File.open(args[:failed_csv]))
    cleaner.deactivate_subscribers(dry_run: dry_run)
  end

  desc "End subscriptions for subscribers who have been improperly deactivated"
  task ended_but_not_deactivated_subscriptions: :environment do
    # there are a lot of subscriptioncontents, so do this iteratively
    # to avoid loading a huge number of subscriptions into memory and
    # then doing 'uniq' on it
    [8.days.ago, 7.days.ago, 6.days.ago, 5.days.ago, 4.days.ago, 3.days.ago, 2.days.ago, 1.day.ago, 10.minutes.ago].each do |timestamp|
      affected = SubscriptionContent.
        where("subscription_contents.created_at < ?", timestamp).
        where(email: nil).
        joins(:subscription).
        merge(Subscription.active).
        map(&:subscription).
        map(&:subscriber_id).
        uniq

      puts "Found #{affected.count} affected subscribers at #{timestamp}"

      affected.each do |subscriber_id|
        subscriber = Subscriber.find(subscriber_id)
        next unless subscriber.deactivated?

        active_subscription_ids = subscriber.active_subscriptions.map(&:id)

        puts "Cleaning up #{subscriber.address}"
        UnsubscribeService.subscriber!(subscriber, :unsubscribed)
        active_subscription_ids.each do |subscription_id|
          SubscriptionContent.where(email_id: nil, subscription_id: subscription_id).each(&:destroy)
        end
      end
    end
  end

  def is_dry_run?
    dry = ENV["DRY_RUN"] != "no"
    puts "Warning: Running in DRY_RUN mode. Use DRY_RUN=no to run live." if dry
    dry
  end
end
