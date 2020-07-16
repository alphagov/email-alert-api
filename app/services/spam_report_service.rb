class SpamReportService
  attr_reader :delivery_attempt

  def self.call(*args)
    new(*args).call
  end

  private_class_method :new

  def initialize(delivery_attempt)
    @delivery_attempt = delivery_attempt
  end

  def call
    subscriber_id = delivery_attempt.email.subscriber_id
    subscriber = Subscriber.find(subscriber_id)

    UnsubscribeService.unsubscribe!(
      subscriber,
      subscriber.active_subscriptions,
      :marked_as_spam,
    )

    delivery_attempt.email.update!(marked_as_spam: true)
  end
end
