class SpamReportService < ApplicationService
  attr_reader :email

  def initialize(email)
    @email = email
  end

  def call
    subscriber_id = email.subscriber_id
    subscriber = Subscriber.find(subscriber_id)
    UnsubscribeAllService.call(subscriber, :marked_as_spam)
    Metrics.marked_as_spam unless email.marked_as_spam?
    email.update!(marked_as_spam: true)
  end
end
