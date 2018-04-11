namespace :bulk do
  desc "Send a bulk email to many subscriber lists"
  task :email, %i(subject body) => :environment do |_t, args|
    subscriber_list_ids = args.extras
    subscriber_lists = SubscriberList.where(id: subscriber_list_ids)

    BulkEmailSenderService.call(
      subject: args.subject,
      body: args.body,
      subscriber_lists: subscriber_lists,
    )
  end
end
