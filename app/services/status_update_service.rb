class StatusUpdateService
  def initialize(reference:, status:, user: nil)
    @reference = reference
    @status = status
    @user = user
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    delivery_attempt.update!(
      status: status.underscore,
      signon_user_uid: user&.uid,
    )

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

private

  attr_reader :reference, :status, :user

  def delivery_attempt
    @delivery_attempt ||= DeliveryAttempt.find_by!(reference: reference)
  end

  def email
    @email ||= delivery_attempt.email
  end

  def subscriber
    @subscriber ||= Subscriber.find_by(address: email.address)
  end
end
