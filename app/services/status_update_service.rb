class StatusUpdateService < ApplicationService
  TEMPORARY_FAILURE_RETRY_DELAY = 6.hours
  TEMPORARY_FAILURE_RETRY_TIMEOUT = 24.hours

  def initialize(reference:, status:, completed_at:, sent_at:, user: nil)
    @reference = reference
    @status = status
    @completed_at = completed_at
    @sent_at = sent_at
    @user = user
    @delivery_attempt = find_delivery_attempt(reference)
  end

  def call
    DeliveryAttempt.transaction do
      delivery_attempt.update!(
        sent_at: sent_at,
        completed_at: completed_at,
        status: status.underscore,
        signon_user_uid: user&.uid,
      )

      UpdateEmailStatusService.call(delivery_attempt)
    rescue ArgumentError
      # This is because Rails doesn't currently do validations for enums
      # see: https://github.com/rails/rails/issues/13971
      error = "'#{status}' is not a supported status"
      GovukError.notify(error)
      raise DeliveryAttemptInvalidStatusError, error
    end

    if delivery_attempt.permanent_failure? && subscriber
      UnsubscribeService.call(subscriber, subscriber.active_subscriptions, :non_existent_email)
    # We check for a status of nil here too in case email hasn't had a status set
    elsif delivery_attempt.temporary_failure? && ["pending", nil].include?(email.status)
      DeliveryRequestWorker.perform_in(TEMPORARY_FAILURE_RETRY_DELAY, email.id, :default)
    end

    Metrics.delivery_attempt_status_changed(status.underscore)
    GovukStatsd.increment("status_update.success")
  rescue StandardError
    GovukStatsd.increment("status_update.failure")
    raise
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

  class DeliveryAttemptInvalidStatusError < RuntimeError; end
  class DeliveryAttemptStatusConflictError < RuntimeError; end
end
