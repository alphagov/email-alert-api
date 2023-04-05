namespace :bulk_email do
  desc "Send a bulk email to many subscriber lists. Any email addresses in config/bulk_email/email_addresses.txt will be skipped."
  task :for_lists, [] => :environment do |_t, args|
    subscriber_lists = SubscriberList.where(id: args.extras)
    email_ids = BulkSubscriberListEmailBuilder.call(
      subject: ENV.fetch("SUBJECT"),
      body: ENV.fetch("BODY"),
      subscriber_lists:,
    )
    email_ids.each do |id|
      SendEmailWorker.perform_async_in_queue(id, queue: :send_email_immediate)
    end
    puts "Sending #{email_ids.count} emails to subscribers on the following lists: #{subscriber_lists.pluck(:slug).join(', ')}"
  end

  desc "Send a bulk email to many subscriber lists but only if the subscriber's email addresses are in config/bulk_email/email_addresses.txt."
  task :for_lists_and_explicitly_including_addresses, [] => :environment do |_t, args|
    subscriber_lists = SubscriberList.where(id: args.extras)
    email_ids = BulkSubscriberListEmailBuilderWithAccount.call(
      subject: ENV.fetch("SUBJECT"),
      body: ENV.fetch("BODY"),
      subscriber_lists:,
    )
    email_ids.each do |id|
      SendEmailWorker.perform_async_in_queue(id, queue: :send_email_immediate)
    end
    puts "Sending #{email_ids.count} emails to subscribers on the following lists: #{subscriber_lists.pluck(:slug).join(', ')}"
  end

  desc "Send an apology email following an incident"
  task :temp_incident_new_subscribers, [] => :environment do
    affected_subscribers = []
    Subscription.where(created_at: Time.zone.local(2023, 2, 8, 14, 38)..Time.zone.local(2023, 4, 4, 14, 24)).find_in_batches do |subscriptions|
      affected_subscribers << subscriptions.select { |subscription| subscription.subscriber_list.content_id.present? }.map(&:subscriber).map(&:address)
    end

    unique_email_addresses = affected_subscribers.flatten.uniq

    explanation = <<~BODY
      Hello,

      You recently signed up to email notifications on GOV.UK. Due to an update to our system you may not have been subscribed to all updates you expected since 8th February 2023.

      If the subscription appears in ‘Manage your GOV.UK email subscriptions’ (https://www.gov.uk/email/manage) but you have not received them, we recommend that you unsubscribe and sign up again for notifications through the GOV.UK website. You will then be sent a new confirmation link.

      Travel alerts and subscriptions to the ‘alerts, recalls and safety information: drugs and medical devices’ (https://www.gov.uk/drug-device-alerts) have not been affected.

      Apologies for any inconvenience,
      GOV.UK Team
    BODY

    follow_up_emails = []

    ApplicationRecord.transaction do
      follow_up_emails = unique_email_addresses.map do |email|
        next if email.blank? # this is only an issue in integration, where the data sync appears to have wiped some addresses

        Email.create!(
          subject: "Action needed on email notifications",
          body: explanation,
          address: email,
        )
      end
    end

    follow_up_emails.each do |email|
      next if email.nil?

      SendEmailWorker.perform_async_in_queue(email.id, queue: :send_email_immediate)
    end
  end
end
