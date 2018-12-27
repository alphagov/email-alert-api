namespace :content_change_email do
  desc "Produce a report on sent and failed emails for a given content change"
  task :status_count, [:id] => :environment do |_t, args|
    content_change = ContentChange.find(args[:id])
    ContentChangeEmailStatusCount.call(content_change)
  end
end
