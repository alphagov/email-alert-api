class DeliverToSubscriberWorker
  include Sidekiq::Worker

  def perform(subscriber_id, email_id)
    subscriber = Subscriber.find(subscriber_id)
    email = Email.find(email_id)
    DeliverToSubscriber.call(subscriber: subscriber, email: email)
  end
end
