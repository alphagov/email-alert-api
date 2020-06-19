namespace :troubleshoot do
  desc "Query the Notify API for email(s) by reference"
  task :get_notifications_from_notify, [:reference] => :environment do |_t, args|
    NotificationsFromNotify.call(args[:reference])
  end

  desc "Query the Notify API for email(s) by email ID"
  task :get_notifications_from_notify_by_email_id, [:id] => :environment do |_t, args|
    delivery_attempts = DeliveryAttempt.where(email_id: args[:id])

    if delivery_attempts.count.zero?
      puts "No results returned"
    else
      delivery_attempts.each do |delivery_attempt|
        NotificationsFromNotify.call(delivery_attempt.id)
      end
    end
  end

  desc "Send a test email to a subscriber by id"
  task :deliver_to_subscriber, [:id] => :environment do |_t, args|
    subscriber = Subscriber.find(args[:id])
    email = Email.create(
      address: subscriber.address,
      subject: "Test email",
      body: "This is a test email.",
      subscriber_id: subscriber.id,
    )
    DeliveryRequestWorker.perform_async_in_queue(email.id, queue: :delivery_immediate)
  end

  desc "Send a test email to an email address"
  task :deliver_to_test_email, [:test_email_address] => :environment do |_t, args|
    email = Email.create(
      address: args[:test_email_address],
      subject: "Test email",
      body: "This is a test email.",
    )
    DeliveryRequestWorker.perform_async_in_queue(email.id, queue: :delivery_immediate)
  end

  namespace :resend_failed_emails do
    desc "Re-send failed emails by email ids"
    task by_id: [:environment] do |_, args|
      resend_failed_emails(Email.where(id: args.to_a))
    end

    desc "Re-send failed emails by date range"
    task :by_date, %i[from to] => [:environment] do |_, args|
      from = Time.iso8601(args.fetch(:from))
      to = Time.iso8601(args.fetch(:to))
      resend_failed_emails(Email.where(created_at: from..to))
    end
  end
end

def resend_failed_emails(scope)
  ids = scope.where(status: :failed).pluck(:id)
  puts "Resending #{ids.length} emails"

  ids.each do |id|
    DeliveryRequestWorker.perform_async_in_queue(id, queue: :delivery_immediate_high)
  end
end
