namespace :bulk do
  desc "Send a bulk email to many subscriber lists"
  task :email, [] => :environment do |_t, args|
    emails = BulkEmailBuilder.call(
      subject: ENV.fetch("SUBJECT"),
      body: ENV.fetch("BODY"),
      subscriber_lists: SubscriberList.where(id: args.extras),
    )

    BulkEmailSenderService.call(bulk_email_builder: emails)
  end
end
