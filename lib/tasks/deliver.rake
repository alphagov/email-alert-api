namespace :deliver do
  task :to_subscriber, [:id] => :environment do |_t, args|
    subscriber = Subscriber.find(args[:id])
    email = OpenStruct.new(subject: "Test email", body: "This is a test email.")
    DeliverToSubscriber.call(subscriber: subscriber, email: email)
  end
end
