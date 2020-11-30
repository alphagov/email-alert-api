namespace :report do
  desc "Outputs a CSV of content changes by subscriber list"
  task matched_content_changes: :environment do
    puts Reports::MatchedContentChangesReport.new.call(start_time: ENV["START_DATE"],
                                                       end_time: ENV["END_DATE"])
  end

  desc "Outputs a CSV of information for each subscriber list within a year for a past date, format: 'yyyy-mm-dd'"
  task :csv_subscriber_lists, [:date] => :environment do |_t, args|
    options = { slugs: ENV.fetch("SLUGS", ""), tags_pattern: ENV["TAGS_PATTERN"], links_pattern: ENV["LINKS_PATTERN"] }
    puts Reports::SubscriberListsReport.new(args[:date], **options).call
  end

  desc "Temporary report for subscribers taking action in switching immediate subscribers to daily digest"
  task subscription_changes_after_switch_to_daily_digest: :environment do
    Reports::SubscriptionChangesAfterSwitchToDailyDigestReport.call
  end
end
