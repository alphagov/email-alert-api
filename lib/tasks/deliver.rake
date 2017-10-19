namespace :deliver do
  task :to_subscriber, [:id] => :environment do |_t, args|
    subscriber = Subscriber.find(args[:id])
    DeliverToSubscriber.call(subscriber: subscriber)
  end
end
