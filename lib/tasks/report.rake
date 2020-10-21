namespace :report do
  desc "Query how many active subscribers there are to the given subscription slug"
  task :count_subscribers, %i[subscription_list_slug] => :environment do |_t, args|
    Reports::CountSubscribersReport.new.call(slug: args[:subscription_list_slug])
  end

  desc "Query how many active subscribers there are to the given subscription slug at the given point in time"
  task :count_subscribers_on, %i[date subscription_list_slug] => :environment do |_t, args|
    Reports::CountSubscribersOnReport.new.call(slug: args[:subscription_list_slug],
                                               date: args[:date])
  end

  desc "Outputs a CSV of content changes by subscriber list"
  task matched_content_changes: :environment do
    puts Reports::MatchedContentChangesReport.new.call(start_time: ENV["START_DATE"],
                                                       end_time: ENV["END_DATE"])
  end

  desc "Export the number of subscriptions for the 'Living in' taxons for European countries as of a given date (format: 'yyyy-mm-dd')"
  task :csv_from_living_in_europe, [:date] => :environment do |_, args|
    Reports::LivingInEuropeReport.new.call(args.date)
  end

  desc "Export all subscriptions to Brexit related content"
  task csv_brexit_subscribers: :environment do
    Reports::BrexitSubscribersReport.call
  end

  desc "
  Export all subscriptions to Brexit related content that were subscribed to before the given date.
  Usage
  report:csv_brexit_subscribers_on_or_before[yyyy-mm-dd]"
  task :csv_brexit_subscribers_on_or_before, [:date] => [:environment] do |_task, args|
    raise "Enter a date" if args[:date].empty?

    date = begin
             Date.parse(args[:date].to_s)
           rescue ArgumentError
             raise 'Invalid date. Please use "yyyy-mm-dd"'
           end

    Reports::BrexitSubscribersReport.call(date)
  end

  desc "Temporary report for subscribers taking action in switching immediate subscribers to daily digest"
  task subscription_changes_after_switch_to_daily_digest: :environment do
    Reports::SubscriptionChangesAfterSwitchToDailyDigestReport.call
  end
end
