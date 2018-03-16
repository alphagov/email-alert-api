namespace :deliver do
  def test_email(address)
    Email.create(
      address: address,
      subject: "Test email",
      body: "This is a test email."
    )
  end

  desc "Send a test email to a subscriber by id"
  task :to_subscriber, [:id] => :environment do |_t, args|
    email = test_email(Subscriber.find(args[:id]).address)
    DeliveryRequestWorker.perform_async_in_queue(email.id, queue: :delivery_immediate)
  end

  desc "Send a test email to an email address"
  task :to_test_email, [:test_email_address] => :environment do |_t, args|
    email = test_email(args[:test_email_address])
    DeliveryRequestWorker.perform_async_in_queue(email.id, queue: :delivery_immediate)
  end
end
