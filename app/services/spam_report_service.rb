class SpamReportService < ApplicationService
  attr_reader :delivery_attempt

  def initialize(delivery_attempt)
    @delivery_attempt = delivery_attempt
  end

  def call
    subscriber_id = delivery_attempt.email.subscriber_id
    subscriber = Subscriber.find(subscriber_id)

    UnsubscribeService.call(
      subscriber,
      subscriber.active_subscriptions,
      :marked_as_spam,
    )

    delivery_attempt.email.update!(marked_as_spam: true)
  end
end
