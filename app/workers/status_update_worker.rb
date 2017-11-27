class StatusUpdateWorker
  include Sidekiq::Worker
  include Sidekiq::Symbols

  def perform(reference:, status:)
    delivery_attempt = DeliveryAttempt.find_by!(reference: reference)
    delivery_attempt.update!(status: status.underscore)

    subscriber = lookup_subscriber(delivery_attempt)

    if subscriber && delivery_attempt.permanent_failure?
      UnsubscribeService.subscriber!(subscriber)
    end
  end

private

  def lookup_subscriber(delivery_attempt)
    address = delivery_attempt.email.address
    Subscriber.find_by(address: address)
  end
end
