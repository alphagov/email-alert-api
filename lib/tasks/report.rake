require "aws-sdk-s3"

namespace :report do
  desc "Outputs a CSV of content changes by subscriber list"
  task matched_content_changes: :environment do
    filename = "matched_content_changes_#{Time.zone.now.utc.strftime('%Y%m%d%H%M%S')}.csv"

    bucket = ENV["AWS_S3_ASSET_BUCKET_NAME"]
    key = "data/email-alert-api/#{filename}"

    s3 = Aws::S3::Client.new
    output = Reports::MatchedContentChangesReport.new.call(
      start_time: ENV["START_DATE"],
      end_time: ENV["END_DATE"],
    )

    s3.put_object({ body: output, bucket:, key: })
    puts "File uploaded to S3 bucket successfully: #{bucket}, #{key}"
  end

  desc "Outputs a CSV of information for each subscriber list within a year for a past date, format: 'yyyy-mm-dd'"
  task :csv_subscriber_lists, [:date] => :environment do |_t, args|
    options = { slugs: ENV.fetch("SLUGS", ""), tags_pattern: ENV["TAGS_PATTERN"], links_pattern: ENV["LINKS_PATTERN"], headers: ENV["HEADERS"] }
    filename = "csv_subscriber_list_#{Time.zone.now.utc.strftime('%Y%m%d%H%M%S')}.csv"

    bucket = ENV["AWS_S3_ASSET_BUCKET_NAME"]
    key = "data/email-alert-api/#{filename}"

    s3 = Aws::S3::Client.new
    output = Reports::SubscriberListsReport.new(args[:date], **options).call

    s3.put_object({ body: output, bucket:, key: })
    puts "File uploaded to S3 bucket successfully: #{bucket}, #{key}"
  end

  desc "Find subscriber lists by title match"
  task :find_subscriber_list_by_title, %i[title] => :environment do |_t, args|
    title = args[:title]
    subscriber_lists = SubscriberList.where("title ILIKE ?", "%#{title}%")

    if subscriber_lists.present?
      puts "Found #{subscriber_lists.count} subscriber lists containing '#{title}'"

      subscriber_lists.each do |subscriber_list|
        puts "============================="
        puts "title: #{subscriber_list.title}"
        puts "slug: #{subscriber_list.slug}"
      end
    else
      raise "Cannot find any subscriber lists with title containing `#{title}`"
    end
  end

  desc "Outputs a CSV of subscriber lists that appear to be inactive (tech debt)"
  task potentially_dead_lists: :environment do
    filename = "potentially_dead_lists_#{Time.zone.now.utc.strftime('%Y%m%d%H%M%S')}.csv"

    bucket = ENV["AWS_S3_ASSET_BUCKET_NAME"]
    key = "data/email-alert-api/#{filename}"

    s3 = Aws::S3::Client.new
    output = Reports::PotentiallyDeadListsReport.new.call

    s3.put_object({ body: output, bucket:, key: })
    puts "File uploaded to S3 bucket successfully: #{bucket}, #{key}"
  end

  desc "Output a simple count of subscribers by the subscriber_list URL"
  task :subscriber_list_subscriber_count, %i[url active_on_date] => :environment do |_t, args|
    puts Reports::SubscriberListSubscriberCountReport.new(
      args.fetch(:url),
      args[:active_on_date],
    ).call
  end

  desc "Output a simple count of active subscribers by subscriber_list slug"
  task :subscriber_list_by_slug_subscriber_count, %i[slug] => :environment do |_t, args|
    puts Reports::SubscriberListBySlugSubscriberCountReport.new(
      args.fetch(:slug),
    ).call
  end

  desc "Output a subscribers count list for past dates by the subscriber_list URL"
  task :subscriber_count_list, %i[url start_date end_date] => :environment do |_t, args|
    puts Reports::SubscriberCountListReport.new(
      args.fetch(:url),
      args[:start_date],
      args[:end_date],
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
      args.fetch(:draft, "false").downcase == "true",
    ).call
  end

  desc "Output how many people are subscribed to lists created from a finder at the given path"
  task :finder_statistics, %i[govuk_path] => :environment do |_t, args|
    puts Reports::FinderStatisticsReport.new(
      args.fetch(:govuk_path),
    ).call
  end

  desc "Outputs CSVs of content changes by publishing organisation, grouped by month and week"
  task content_changes_by_organisation: :environment do
    months = ENV.fetch("MONTHS", 12).to_i
    raise ArgumentError, "MONTHS must be greater than 0" unless months.positive?

    start_date = months.months.ago
    end_date = Time.current

    org_names = GdsApi.organisations.organisations.with_subsequent_pages.to_h do |org|
      [org.dig("details", "content_id"), org["title"]]
    end

    monthly_counts = Hash.new(0)
    weekly_counts = Hash.new(0)

    ContentChange.where(created_at: start_date..end_date).find_each do |content_change|
      org_ids =
        content_change.links[:primary_publishing_organisation] ||
        []

      month = content_change.created_at.to_date.beginning_of_month
      week = content_change.created_at.to_date.beginning_of_week(:monday)

      org_ids.each do |content_id|
        org_title = org_names[content_id]
        next unless org_title

        monthly_counts[[month, org_title]] += 1
        weekly_counts[[week, org_title]] += 1
      end
    end

    build_csv = lambda do |period_header, counts|
      CSV.generate do |csv|
        csv << [period_header, "organisation", "content_changes"]

        counts
          .sort_by { |(period, organisation), _count| [period, organisation] }
          .each do |(period, organisation), count|
            csv << [period.iso8601, organisation, count]
          end
      end
    end

    timestamp = Time.zone.now.utc.strftime("%Y%m%d%H%M%S")
    bucket = ENV["AWS_S3_ASSET_BUCKET_NAME"]
    s3 = Aws::S3::Client.new

    reports = {
      "monthly" => build_csv.call("month_starting", monthly_counts),
      "weekly" => build_csv.call("week_starting", weekly_counts),
    }

    reports.each do |period, output|
      filename = "content_changes_by_organisation_#{period}_#{timestamp}.csv"
      key = "data/email-alert-api/#{filename}"

      s3.put_object(
        body: output,
        bucket:,
        key:,
        content_type: "text/csv",
      )

      puts "File uploaded to S3 bucket successfully: #{bucket}, #{key}"
    end
  end

  desc "Outputs CSVs of email updates recipients by publishing organisation, grouped by month and week"
  task subscribers_by_organisation: :environment do
    org_names = GdsApi.organisations.organisations.with_subsequent_pages.to_h do |org|
      [org.dig("details", "content_id"), org["title"]]
    end

    monthly_counts = Hash.new(0)
    weekly_counts = Hash.new(0)

    start_time = ENV.fetch("MONTHS", 12).to_i.months.ago
    end_time = Time.current

    subscription_counts = {}

    content_changes = ContentChange.where(created_at: start_time..end_time)
    total = content_changes.count
    processed = 0
    batch_size = ENV.fetch("BATCH_SIZE", 100).to_i

    puts "Processing #{total} content changes..."

    content_changes
      .includes(matched_content_changes: :subscriber_list)
      .find_each(batch_size: batch_size) do |content_change|
      processed += 1
      if (processed % batch_size).zero?
        percentage = (processed.to_f / total * 100).round(1)
        puts "Processed #{processed}/#{total} content changes (#{percentage}%)"
      end

      month = content_change.created_at.strftime("%Y-%m")
      week = content_change.created_at.to_date.beginning_of_week(:monday).iso8601

      org_ids =
        content_change.links[:primary_publishing_organisation] ||
        []

      # Number of active subscriptions matched to each content change at that point in time
      subscriber_count = content_change.matched_content_changes.sum do |match|
        subscriber_list = match.subscriber_list
        cache_key = [subscriber_list.id, content_change.created_at.to_date]

        subscription_counts[cache_key] ||= subscriber_list
          .subscriptions
          .active_on(content_change.created_at.to_date)
          .count
      end

      org_ids.each do |content_id|
        org_title = org_names[content_id]
        next unless org_title

        monthly_counts[[month, org_title]] += subscriber_count
        weekly_counts[[week, org_title]] += subscriber_count
      end
    end

    monthly_csv = CSV.generate do |csv|
      csv << %w[month organisation notification_recipients]

      monthly_counts
        .sort_by { |(month, org), _| [month, org] }
        .each do |(month, org), count|
          csv << [month, org, count]
        end
    end

    weekly_csv = CSV.generate do |csv|
      csv << %w[week_starting organisation notification_recipients]

      weekly_counts
        .sort_by { |(week, org), _| [week, org] }
        .each do |(week, org), count|
          csv << [week, org, count]
        end
    end

    timestamp = Time.zone.now.utc.strftime("%Y%m%d%H%M%S")
    bucket = ENV["AWS_S3_ASSET_BUCKET_NAME"]
    s3 = Aws::S3::Client.new

    reports = {
      "monthly" => monthly_csv,
      "weekly" => weekly_csv,
    }

    reports.each do |period, output|
      filename = "notification_recipients_by_organisation_#{period}_#{timestamp}.csv"
      key = "data/email-alert-api/#{filename}"

      s3.put_object(
        body: output,
        bucket:,
        key:,
        content_type: "text/csv",
      )

      puts "File uploaded to S3 bucket successfully: #{bucket}, #{key}"
    end
  end
end
