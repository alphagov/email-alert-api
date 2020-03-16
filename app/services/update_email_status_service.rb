class UpdateEmailStatusService
  def initialize(delivery_attempt)
    @delivery_attempt = delivery_attempt
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    handle_temporary_failure if delivery_attempt.temporary_failure?
    handle_permanent_failure if delivery_attempt.permanent_failure?
    handle_delivered if delivery_attempt.delivered?
  end

  private_class_method :new

private

  attr_reader :delivery_attempt
  delegate :email, to: :delivery_attempt

  def handle_temporary_failure
    return unless retries_exhausted?

    email.update!(
      status: :failed,
      failure_reason: :retries_exhausted_failure,
      finished_sending_at: delivery_attempt.finished_sending_at,
    )
  end

  def retries_exhausted?
    first_completed = DeliveryAttempt
                       .where(email: email, status: :temporary_failure)
                       .minimum(:completed_at)

    first_completed && first_completed < StatusUpdateService::TEMPORARY_FAILURE_RETRY_TIMEOUT.ago
  end

  def handle_permanent_failure
    email.update!(
      status: :failed,
      failure_reason: :permanent_failure,
      finished_sending_at: delivery_attempt.finished_sending_at,
    )
  end

  def handle_delivered
    email.update!(
      status: :sent,
      finished_sending_at: delivery_attempt.finished_sending_at,
    )
  end
end
