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
end
