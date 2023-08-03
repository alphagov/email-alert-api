namespace :report do
  desc "Outputs a CSV of content changes by subscriber list"
  task matched_content_changes: :environment do
    puts Reports::MatchedContentChangesReport.new.call(start_time: ENV["START_DATE"],
                                                       end_time: ENV["END_DATE"])
  end

  desc "Outputs a CSV of information for each subscriber list within a year for a past date, format: 'yyyy-mm-dd'"
  task :csv_subscriber_lists, [:date] => :environment do |_t, args|
    options = { slugs: ENV.fetch("SLUGS", ""), tags_pattern: ENV["TAGS_PATTERN"], links_pattern: ENV["LINKS_PATTERN"], headers: ENV["HEADERS"] }
    puts Reports::SubscriberListsReport.new(args[:date], **options).call
  end

  desc "Outputs a CSV of subscriber lists that appear to be inactive (tech debt)"
  task potentially_dead_lists: :environment do
    puts Reports::PotentiallyDeadListsReport.new.call
  end

  desc "Output a simple count of subscribers by the subscrber_list URL"
  task :subscriber_list_subscriber_count, %i[url active_on_date] => :environment do |_t, args|
    puts Reports::SubscriberListSubscriberCountReport.new(
      args.fetch(:url),
      args[:active_on_date],
    ).call
  end

  desc "Output a report of top single page notification subscriber lists"
  task :single_page_notifications_top_subscriber_lists, %i[limit] => :environment do |_t, args|
    puts Reports::SinglePageNotificationsReport.new(args[:limit] || 25).call.join("\n")
  end

  desc "Output how many people were notified for recent content changes to the page at the given path"
  task :historical_content_change_statistics, %i[govuk_path] => :environment do |_t, args|
    puts Reports::HistoricalContentChangeStatisticsReport.new(
      args.fetch(:govuk_path),
    ).call
  end

  desc "Output how many people would be notified if a major change were published at the given path"
  task :future_content_change_statistics, %i[govuk_path draft] => :environment do |_t, args|
    puts Reports::FutureContentChangeStatisticsReport.new(
      args.fetch(:govuk_path),
      args.fetch(:draft).downcase == "true",
    ).call
  end
end
