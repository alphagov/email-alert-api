class DeliveryRequestWorker
  include Sidekiq::Worker

  attr_reader :priority, :email

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

  sidekiq_retry_in do |count|
    10 * (count + 1) # 10, 20, 30, 40 ish
  end

  sidekiq_retries_exhausted do |msg, _e|
    reschedule_job if msg["error_class"] == "RatelimitExceededError"
  end

  def perform(email_id)
    @email = Email.find(email_id)
    check_rate_limit!
    increment_rate_limiter
    DeliverEmailService.call(email: email)
  end

  def self.perform_async_with_priority(*args, priority:)
    @priority = priority
    set(queue: queue_for_priority(priority))
      .perform_async(*args)
  end

  def self.perform_in_with_priority(*args, priority:)
    @priority = priority
    set(queue: queue_for_priority(priority))
      .perform_in(*args)
  end

  def check_rate_limit!
    if rate_limit_exceeded?
      GovukStatsd.increment("delivery_request_worker.rate_limit_exceeded")
      raise RatelimitExceededError
    end
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

  def reschedule_job
    GovukStatsd.increment("delivery_request_worker.rescheduled")
    DeliveryRequestWorker.perform_in_with_priority(30.seconds, email.id, priority)
  end
end

class RatelimitExceededError < StandardError; end
