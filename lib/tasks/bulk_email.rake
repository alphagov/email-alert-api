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

  desc "Send an apology email following an incident"
  task :temp_incident_new_subscribers, [] => :environment do
    affected_emails = Email
      .where(subject: "Confirm that you want to get emails from GOV.UK")
      .where("created_at > ? AND created_at < ?", Time.zone.local(2021, 1, 7, 14, 33), Time.zone.local(2021, 1, 8, 13, 45))
      .uniq(&:address)

    explanation = <<~BODY
      Hello,

      You recently signed up to email notifications for a topic on GOV.UK. Unfortunately, the confirmation email you were sent contained an invalid link and your subscription was not confirmed.

      If you still wish to subscribe, please sign up again through the GOV.UK website. You will then be sent a new confirmation link.

      Apologies for any inconvenience,

      GOV.UK emails
    BODY

    follow_up_emails = []

    ApplicationRecord.transaction do
      follow_up_emails = affected_emails.map do |email|
        Email.create!(
          subject: "Re: Confirm that you want to get emails from GOV.UK",
          body: explanation,
          address: email.address,
        )
      end
    end

    follow_up_emails.each do |email|
      SendEmailWorker.perform_async_in_queue(email.id, queue: :send_email_immediate)
    end
  end
end
