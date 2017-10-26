class DeliverToSubscriberWorker
  include Sidekiq::Worker

  sidekiq_options retry: 3

  def perform(subscriber_id, email_id)
    subscriber = Subscriber.find(subscriber_id)
    email = Email.find(email_id)
    DeliverToSubscriber.call(subscriber: subscriber, email: email)
  end
end
