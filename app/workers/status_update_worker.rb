class StatusUpdateWorker
  include Sidekiq::Worker
  include Sidekiq::Symbols

  def perform(reference:, status:)
    delivery_attempt = DeliveryAttempt.find_by!(reference: reference)
    delivery_attempt.update!(status: status.underscore)

    subscriber = lookup_subscriber(delivery_attempt)
    subscriber.unsubscribe! if subscriber && delivery_attempt.permanent_failure?
  end

private

  def lookup_subscriber(delivery_attempt)
    address = delivery_attempt.email.address
    Subscriber.find_by(address: address)
  end
end
