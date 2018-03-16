class StatusUpdateService
  def initialize(reference:, status:, completed_at:, sent_at:, user: nil)
    @reference = reference
    @status = status
    @completed_at = completed_at
    @sent_at = sent_at
    @user = user
    @delivery_attempt = find_delivery_attempt(reference)
  end

  def self.call(*args)
    DeliveryAttempt.transaction { new(*args).call }
  end

  def call
    begin
      delivery_attempt.update!(
        sent_at: sent_at,
        completed_at: completed_at,
        status: status.underscore,
        signon_user_uid: user&.uid,
      )

      email.finish_sending(delivery_attempt) if delivery_attempt.has_final_status?
    rescue ArgumentError
      # This is because Rails doesn't currently do validations for enums
      # see: https://github.com/rails/rails/issues/13971
      error = "'#{status}' is not a supported status"
      GovukError.notify(error)
      raise DeliveryAttemptInvalidStatusError, error
    end

    if delivery_attempt.permanent_failure? && subscriber
      UnsubscribeService.subscriber!(subscriber, :non_existant_email)
    elsif delivery_attempt.temporary_failure?
      redeliver_email(email)
    end

    GovukStatsd.increment("status_update.success")
  rescue StandardError
    GovukStatsd.increment("status_update.failure")
    raise
  end

  private_class_method :new

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

    if !attempt.sending?
      raise DeliveryAttemptStatusConflictError, "Status update already received"
    end

    attempt
  end

  def redelivery_delay(email)
    case email.delivery_attempts.count
    when 1
      5.minutes
    when 2
      1.hour
    when 3
      24.hours
    end
  end

  def redeliver_email(email)
    delay = redelivery_delay(email)

    if delay.nil?
      Rails.logger.info("Given up trying to send #{email}.")
      return
    end

    DeliveryRequestWorker.perform_in(delay, email.id, :default)
  end

  class DeliveryAttemptInvalidStatusError < RuntimeError; end
  class DeliveryAttemptStatusConflictError < RuntimeError; end
end
