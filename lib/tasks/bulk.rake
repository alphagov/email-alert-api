namespace :bulk do
  desc "Send a bulk email to many subscriber lists"
  task :email, [] => :environment do |_t, args|
    email_ids = BulkEmailBuilder.call(
      subject: ENV.fetch("SUBJECT"),
      body: ENV.fetch("BODY"),
      subscriber_lists: SubscriberList.where(id: args.extras),
    )

    email_ids.each do |id|
      DeliveryRequestWorker.perform_async_in_queue(id, queue: :delivery_immediate)
    end
  end
end
