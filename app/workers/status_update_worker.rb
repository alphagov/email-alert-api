class StatusUpdateWorker
  include Sidekiq::Worker

  attr_accessor :reference, :status

  def perform(params)
    params.deep_symbolize_keys!

    self.reference = params.fetch(:reference)
    self.status = params.fetch(:status).underscore

    set_status_on_delivery_attempt
    unsubscribe_if_permanent_failure
  end

private

  def set_status_on_delivery_attempt
    delivery_attempt.status = status
    delivery_attempt.save!
  end

  def unsubscribe_if_permanent_failure
    return unless delivery_attempt.status == "permanent_failure" # TODO
    return unless subscriber

    subscriber.unsubscribe!
  end

  def delivery_attempt
    @delivery_attempt ||= DeliveryAttempt.find_by!(reference: reference)
  end

  def subscriber
    address = delivery_attempt.email.address
    @subscriber ||= Subscriber.find_by(address: address)
  end
end
