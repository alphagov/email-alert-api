namespace :bulk_email do
  desc "Send a bulk email to many subscriber lists"
  task :for_lists, [] => :environment do |_t, args|
    email_ids = BulkSubscriberListEmailBuilder.call(
      subject: ENV.fetch("SUBJECT"),
      body: ENV.fetch("BODY"),
      subscriber_lists: SubscriberList.where(id: args.extras),
    )
    email_ids.each do |id|
      SendEmailWorker.perform_async_in_queue(id, queue: :send_email_immediate)
    end
  end
end
