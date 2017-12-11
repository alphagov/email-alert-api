class DeliveryRequestWorker
  include Sidekiq::Worker

  def self.queue_for_priority(priority)
    if priority == :high
      :high_delivery
    elsif priority == :low
      :low_delivery
    else
      raise ArgumentError, "priority should be :high or :low"
    end
  end

  sidekiq_options retry: 3, queue: queue_for_priority(:low)

  def perform(email_id)
    email = Email.find(email_id)
    check_rate_limit!
    increment_rate_limiter
    DeliverEmailService.call(email: email)
  end

  def self.perform_async_with_priority(*args, priority:)
    set(queue: queue_for_priority(priority))
      .perform_async(*args)
  end

  def check_rate_limit!
    raise RatelimitExceededError if rate_limit_exceeded?
  end

  def rate_limit_exceeded?
    rate_limiter.exceeded?("notify", threshold: 18000, interval: 60)
  end

  def rate_limiter
    Services.rate_limiter
  end

  def increment_rate_limiter
    rate_limiter.add("notify")
  end
end

class RatelimitExceededError < StandardError; end
