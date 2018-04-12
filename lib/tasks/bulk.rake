namespace :bulk do
  desc "Send a bulk email to many subscriber lists"
  task :email, [] => :environment do |_t, args|
    BulkEmailSenderService.call(
      subject: ENV.fetch("SUBJECT"),
      body: ENV.fetch("BODY"),
      subscriber_lists: SubscriberList.where(id: args.extras),
    )
  end
end
