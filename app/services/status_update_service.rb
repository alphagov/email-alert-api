class StatusUpdateService
  def initialize(reference:, status:, user: nil)
    @reference = reference
    @status = status
    @user = user
    @delivery_attempt = find_delivery_attempt(reference)
  end

  def self.call(*args)
    DeliveryAttempt.transaction { new(*args).call }
  end

  def call
    begin
      delivery_attempt.update!(
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
      UnsubscribeService.subscriber!(subscriber)
    elsif delivery_attempt.temporary_failure?
      DeliveryRequestWorker.perform_in(15.minutes, email.id, :default)
    end

    GovukStatsd.increment("status_update.success")
  rescue StandardError
    GovukStatsd.increment("status_update.failure")
    raise
  end

  private_class_method :new

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
                .find_by!(id: reference)

    if !attempt.sending?
      raise DeliveryAttemptStatusConflictError, "Status update already received"
    end

    attempt
  end

  class DeliveryAttemptInvalidStatusError < RuntimeError; end
  class DeliveryAttemptStatusConflictError < RuntimeError; end
end
