namespace :bulk_email do
  desc "Send a bulk email to many subscriber lists"
  task :for_lists, [] => :environment do |_t, args|
    email_ids = BulkSubscriberListEmailBuilder.call(
      subject: ENV.fetch("SUBJECT"),
      body: ENV.fetch("BODY"),
      subscriber_lists: SubscriberList.where(id: args.extras),
    )
    email_ids.each do |id|
      DeliveryRequestWorker.perform_async_in_queue(id, queue: :delivery_immediate)
    end
  end

  desc "Email all subscribers of the Brexit checker"
  task brexit_subscribers: :environment do
    brexit_lists = SubscriberList.where("subscriber_lists.tags->>'brexit_checklist_criteria' IS NOT NULL")
    Rake::Task["bulk_email:for_lists"].invoke(*brexit_lists)
  end
end
