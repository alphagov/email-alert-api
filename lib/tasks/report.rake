namespace :report do
  desc "Outputs a CSV of content changes by subscriber list"
  task matched_content_changes: :environment do
    puts Reports::MatchedContentChangesReport.new.call(start_time: ENV["START_DATE"],
                                                       end_time: ENV["END_DATE"])
  end

  desc <<~DESCRIPTION
    Produce a report on sent, pending and failed emails for given content change id or ids
    At least one ContentChange id must be given. Usage:
    - report:content_change_email_status_count[id_1]
    - report:content_change_email_status_count[id_1,id_2,id_n]
  DESCRIPTION
  task content_change_email_status_count: :environment do |_t, args|
    Reports::ContentChangeEmailStatusCount.call(ids: args.extras)
  end

  desc <<~DESCRIPTION
    Produce a report on failed emails for given content change id or ids
    At least one ContentChange id must be given. Usage:
    - report:content_change_failed_emails[id_1]
    - report:content_change_failed_emails[id_1,id_2,id_n]
  DESCRIPTION
  task content_change_failed_emails: :environment do |_t, args|
    Reports::ContentChangeEmailFailures.call(ids: args.extras)
  end

  desc "Query how many active subscribers there are to the given subscription slug"
  task :count_subscribers, %i[subscription_list_slug] => :environment do |_t, args|
    Reports::CountSubscribersReport.new.call(slug: args[:subscription_list_slug])
  end

  desc "Query how many active subscribers there are to the given subscription slug at the given point in time"
  task :count_subscribers_on, %i[date subscription_list_slug] => :environment do |_t, args|
    Reports::CountSubscribersOnReport.new.call(slug: args[:subscription_list_slug],
                                               date: args[:date])
  end

  desc "Find successful delivery attempts between two dates/times and calculate average (seconds)"
  task :find_delivery_attempts, %i[start_date end_date] => :environment do |_t, args|
    Reports::FindDeliveryAttemptsReport.new(args[:start_date], args[:end_date]).report
  end

  desc "Export the number of subscriptions for a collection of lists given as arguments of list IDs"
  task csv_from_ids: :environment do |_, args|
    Reports::DataExporter.new.export_csv_from_ids(args.to_a)
  end

  desc "Export the number of subscriptions for a collection of lists given as arguments of list IDs at a given date"
  task :csv_from_ids_at, [:date] => :environment do |_, args|
    Reports::DataExporter.new.export_csv_from_ids_at(args.date, args.extras)
  end

  desc "Export the number of subscriptions for a collection of lists given as arguments of list slugs"
  task :csv_from_slugs, [:slugs] => :environment do |_, args|
    Reports::DataExporter.new.export_csv_from_slugs(args.slugs.split)
  end

  desc "Export the number of subscriptions for a collection of lists given as arguments of list slugs at a given date"
  task :csv_from_slugs_at, [:date] => :environment do |_, args|
    Reports::DataExporter.new.export_csv_from_slugs_at(args.date, args.extras)
  end

  desc "Export the number of subscriptions for the 'Living in' taxons for European countries"
  task csv_from_living_in_europe: :environment do
    Reports::DataExporter.new.export_csv_from_living_in_europe
  end

  desc "Export the number of subscriptions to travel advice lists as of a given date (format: 'yyyy-mm-dd')"
  task :csv_from_travel_advice_at, [:date] => :environment do |_, args|
    Reports::DataExporter.new.export_csv_from_travel_advice_at(args.date)
  end

  desc "Produce a report on the unpublishing activity between two dates/times. E.g [2018\06/17 12:20:20, 2018\06/18 13:20:20]"
  task :unpublishing, %i[start_date end_date] => :environment do |_t, args|
    Reports::UnpublishingReport.call(args[:start_date], args[:end_date])
  end
end
