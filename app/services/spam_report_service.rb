class SpamReportService < ApplicationService
  attr_reader :delivery_attempt_id, :email_address

  def initialize(delivery_attempt_id, email_address)
    @delivery_attempt_id = delivery_attempt_id
    @email_address = email_address
  end

  def call
    return if email.marked_as_spam?

    UnsubscribeAllService.call(subscriber, :marked_as_spam)
    Metrics.marked_as_spam
    email.update!(marked_as_spam: true)
  rescue ActiveRecord::RecordNotFound
    UnsubscribeAllService.call(subscriber, :marked_as_spam)
    Metrics.marked_as_spam
  end

private

  def email
    @email ||= DeliveryAttempt.find(delivery_attempt_id).email
  end

  def subscriber
    @subscriber ||= Subscriber.find_by(address: email_address)
  end
end
