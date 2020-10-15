class StatusUpdateService < ApplicationService
  def initialize(reference:, status:, user: nil)
    @reference = reference
    @status = status
    @user = user
    @delivery_attempt = find_delivery_attempt(reference)
  end

  def call
    ApplicationRecord.transaction do
      delivery_attempt.update!(
        status: delivery_attempt_status,
        signon_user_uid: user&.uid,
      )
    end

    if status == "permanent-failure" && subscriber
      UnsubscribeAllService.call(subscriber, :non_existent_email)
    end

    if delivery_attempt_status == :undeliverable_failure
      Rails.logger.warn("Email #{reference} failed with a #{status}")
    end

    GovukStatsd.increment("status_update.status.#{status}")
  end

private

  attr_reader :delivery_attempt, :reference, :status, :user
  delegate :email, to: :delivery_attempt

  def subscriber
    @subscriber ||= Subscriber.find_by(address: email.address)
  end

  def find_delivery_attempt(reference)
    attempt = DeliveryAttempt
                .includes(:email)
                .joins(:email)
                .lock
                .find(reference)

    unless attempt.sent?
      raise DeliveryAttemptStatusConflictError, "Status update already received"
    end

    attempt
  end

  def delivery_attempt_status
    case status
    when "delivered" then :delivered
    # We are deliberatly omitting "technical-failure" as Notify say this is
    # not sent via callback. If we start receiving these we should chat to
    # Notify about why.
    when "permanent-failure", "temporary-failure" then :undeliverable_failure
    else
      error = "Recieved an unexpected status: '#{status}'"
      GovukError.notify(error)
      raise DeliveryAttemptInvalidStatusError, error
    end
  end

  class DeliveryAttemptInvalidStatusError < RuntimeError; end
  class DeliveryAttemptStatusConflictError < RuntimeError; end
end
