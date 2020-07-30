class StatusUpdateService < ApplicationService
  def initialize(reference:, status:, completed_at:, sent_at:, user: nil)
    @reference = reference
    @status = status
    @completed_at = completed_at
    @sent_at = sent_at
    @user = user
    @delivery_attempt = find_delivery_attempt(reference)
  end

  def call
    ApplicationRecord.transaction do
      delivery_attempt.update!(
        sent_at: sent_at,
        completed_at: completed_at,
        status: delivery_attempt_status,
        signon_user_uid: user&.uid,
      )
    end

    update_email_status(delivery_attempt)

    if status == "permanent-failure" && subscriber
      UnsubscribeAllService.call(subscriber, :non_existent_email)
    end

    if delivery_attempt_status == :undeliverable_failure
      Rails.logger.warn("Email #{reference} failed with a #{status}")
    end

    Metrics.delivery_attempt_status_changed(delivery_attempt_status)
    GovukStatsd.increment("status_update.status.#{status}")
  end

private

  attr_reader :delivery_attempt, :reference, :status, :user, :completed_at, :sent_at
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

    unless attempt.sending?
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

  def update_email_status(delivery_attempt)
    finished_sending_at = delivery_attempt.finished_sending_at
    email.mark_as_sent(finished_sending_at) if delivery_attempt.delivered?
    email.mark_as_failed(finished_sending_at) if delivery_attempt.undeliverable_failure?
  end

  class DeliveryAttemptInvalidStatusError < RuntimeError; end
  class DeliveryAttemptStatusConflictError < RuntimeError; end
end
