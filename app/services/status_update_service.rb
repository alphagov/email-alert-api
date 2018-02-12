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
    updates = DeliveryAttempt.where(reference: reference).update_all(
      status: status.underscore,
      signon_user_uid: user&.uid,
    )

    raise ActiveRecord::RecordNotFound unless updates == 1

    if permanent_failure? && subscriber
      UnsubscribeService.subscriber!(subscriber)
    elsif temporary_failure?
      DeliveryRequestWorker.perform_in(15.minutes, email.id, :default)
    end

    GovukStatsd.increment("status_update.success")
  rescue StandardError
    GovukStatsd.increment("status_update.failure")
    raise
  end

  private_class_method :new

private

  attr_reader :reference, :status, :user

  def permanent_failure?
    status == "permanent-failure"
  end

  def temporary_failure?
    status == "temporary-failure"
  end

  def email
    @email ||= DeliveryAttempt.find_by!(reference: reference).email
  end

  def subscriber
    @subscriber ||= Subscriber.find_by(address: email.address)
  end
end
