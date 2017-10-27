namespace :deliver do
  task :to_subscriber, [:id] => :environment do |_t, args|
    subscriber = Subscriber.find(args[:id])
    email = OpenStruct.new(subject: "Test email", body: "This is a test email.")
    DeliverToSubscriber.call(subscriber: subscriber, email: email)
  end

  task :to_test_email, [:test_email_address] => :environment do |_t, args|
    subscriber = Subscriber.new(address: args[:test_email_address])
    email = OpenStruct.new(subject: "Test email", body: "This is a test email.")
    DeliverToSubscriber.call(subscriber: subscriber, email: email)
  end
end
