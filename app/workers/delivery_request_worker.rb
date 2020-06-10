class DeliveryRequestWorker
  include Sidekiq::Worker

  sidekiq_options retry: 9

  sidekiq_retries_exhausted do |msg, _e|
    if msg["error_class"] == "RatelimitExceededError"
      email_id = msg["args"].first
      queue = msg["args"].second
      GovukStatsd.increment("delivery_request_worker.rescheduled")
      DeliveryRequestWorker.set(queue: queue).perform_in(30.seconds, email_id, queue)
    end
  end

  def perform(*args)
    # TODO: Once deployed and all jobs have been processed, this code
    # can be changed to always expect three arguments
    if args.length == 2
      @email_id, @queue = args
    else
      @email_id, content_change_created_at, @queue = args
    end

    check_rate_limit!

    email = MetricsService.delivery_request_worker_find_email do
      Email.find(email_id)
    end

    attempted = DeliveryRequestService.call(
      email: email,
      content_change_created_at: content_change_created_at,
    )
    increment_rate_limiter if attempted
  end

  def self.perform_async_in_queue(*args, queue:)
    set(queue: queue).perform_async(*args, queue)
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

  def increment_rate_limiter
    rate_limiter.add("delivery_request")
  end

  def rate_limit_threshold
    per_minute_to_allow_360_per_second = "21600"
    ENV.fetch("DELIVERY_REQUEST_THRESHOLD", per_minute_to_allow_360_per_second).to_i
  end

  def rate_limit_interval
    minute_in_seconds = "60"
    ENV.fetch("DELIVERY_REQUEST_INTERVAL", minute_in_seconds).to_i
  end

private

  attr_reader :email_id, :queue

  def rate_limiter
    Services.rate_limiter
  end
end

class RatelimitExceededError < StandardError
end
