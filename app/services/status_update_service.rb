class StatusUpdateService
  def initialize(reference:, status:)
    @reference = reference
    @status = status
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    delivery_attempt.update!(status: status.underscore)

    if delivery_attempt.permanent_failure? && subscriber
      UnsubscribeService.subscriber!(subscriber)
    end

    GovukStatsd.increment("status_update.success")
  rescue
    GovukStatsd.increment("status_update.failure")
    raise
  end

private

  attr_reader :reference, :status

  def delivery_attempt
    @delivery_attempt ||= DeliveryAttempt.find_by!(reference: reference)
  end

  def subscriber
    @subscriber ||= begin
      address = delivery_attempt.email.address
      Subscriber.find_by(address: address)
    end
  end
end
