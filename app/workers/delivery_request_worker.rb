class DeliveryRequestWorker
  include Sidekiq::Worker

  attr_reader :email, :queue

  def self.queue_for_immediate(priority)
    if priority == :high
      :delivery_immediate_high
    elsif priority == :normal
      :delivery_immediate
    else
      raise ArgumentError, "priority should be :high or :normal"
    end
  end

  def self.queue_for_digest
    :delivery_digest
  end

  sidekiq_options retry: 3, queue: queue_for_immediate(:normal)

  sidekiq_retry_in do |count|
    10 * (count + 1) # 10, 20, 30, 40 ish
  end

  sidekiq_retries_exhausted do |msg, _e|
    reschedule_job if msg["error_class"] == "RatelimitExceededError"
  end

  def perform(email_id, queue)
    @email = Email.find(email_id)
    @queue = queue
    check_rate_limit!
    increment_rate_limiter
    DeliveryRequestService.call(email: @email)
  end

  def self.perform_async_for_immediate(*args, priority: :normal)
    queue = queue_for_immediate(priority)
    set(queue: queue).perform_async(*args, queue)
  end

  def self.perform_async_for_digest(*args)
    set(queue: queue_for_digest).perform_async(*args, queue_for_digest)
  end

  def check_rate_limit!
    if rate_limit_exceeded?
      GovukStatsd.increment("delivery_request_worker.rate_limit_exceeded")
      raise RatelimitExceededError
    end
  end

  def rate_limit_exceeded?
    rate_limiter.exceeded?(
      "delivery_request",
      threshold: rate_limit_threshold,
      interval: rate_limit_interval,
    )
  end

  def rate_limiter
    Services.rate_limiter
  end

  def increment_rate_limiter
    rate_limiter.add("delivery_request")
  end

  def reschedule_job
    GovukStatsd.increment("delivery_request_worker.rescheduled")
    DeliveryRequestWorker.set(queue: queue).perform_in(30.seconds, email.id, queue)
  end

  def rate_limit_threshold
    per_minute_to_allow_360_per_second = 21600
    ENV["DELIVERY_REQUEST_THRESHOLD"] || per_minute_to_allow_360_per_second
  end

  def rate_limit_interval
    minute_in_seconds = 60
    ENV["DELIVERY_REQUEST_INTERVAL"] || minute_in_seconds
  end
end

class RatelimitExceededError < StandardError; end
