namespace :report do
  desc "Produce a report on sent, pending and failed emails for a given content change"
  task :content_change_email_status_count, [:id] => :environment do |_t, args|
    content_change = ContentChange.find(args[:id])
    Reports::ContentChangeEmailStatusCount.call(content_change)
  end

  desc "Produce a report on failed emails for a given content change"
  task :content_change_failed_emails, [:id] => :environment do |_t, args|
    content_change = ContentChange.find(args[:id])
    Reports::ContentChangeEmailFailures.call(content_change)
  end

  desc "Produce a report on all content_change information between given dates, format - '2019-09-02 11:46:29', defaults to today"
  task :content_changes_information, %i[start_date end_date] => :environment do |_t, args|
    args.with_defaults(start_date: DateTime.now.beginning_of_day, end_date: DateTime.now.end_of_day)
    Reports::ContentChangesInformation.new(args[:start_date], args[:end_date]).report
  end
end
