namespace :report do
  desc "Produce a report on sent and failed emails for a given content change"
  task :content_change_email_status_count, [:id] => :environment do |_t, args|
    content_change = ContentChange.find(args[:id])
    Reports::ContentChangeEmailStatusCount.call(content_change)
  end
end
