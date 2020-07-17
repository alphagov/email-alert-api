class DeliveryRequestWorker
  class RateLimitExceededError < RuntimeError; end

  include Sidekiq::Worker

  sidekiq_options retry: 9

  sidekiq_retries_exhausted do |msg, error|
    next unless error.is_a?(RateLimitExceededError)

    email_id, metrics = msg["args"]
    GovukStatsd.increment("delivery_request_worker.rescheduled")
    DeliveryRequestWorker.set(queue: msg["queue"])
                         .perform_in(5.minutes, email_id, metrics)
  end

  def perform(email_id, metrics = {})
    # existing jobs may have the second parameter set as a string, representing
    # a queue and need their type changing. This can be removed once deployed
    # and the queue is cleared
    metrics = {} unless metrics.is_a?(Hash)

    check_rate_limit_exceeded

    email = Metrics.delivery_request_worker_find_email do
      Email.find(email_id)
    end

    attempted = DeliveryRequestService.call(
      email: email,
      metrics: parsed_metrics(metrics),
    )
    increment_rate_limiter if attempted
  end

  def self.perform_async_in_queue(*args, queue:)
    set(queue: queue).perform_async(*args)
  end

private

  def check_rate_limit_exceeded
    return unless rate_limiter.exceeded?("delivery_request",
                                         threshold: rate_limit_threshold,
                                         interval: rate_limit_interval)

    GovukStatsd.increment("delivery_request_worker.rate_limit_exceeded")
    raise RateLimitExceededError
  end

  # Sidekiq uses JSON for a workers arguments, so richer objects are not
  # available. This converts the scalar values to objects.
  def parsed_metrics(metrics)
    content_change_created_at = metrics["content_change_created_at"]
      &.then { |t| Time.zone.iso8601(t) }

    { content_change_created_at: content_change_created_at }.compact
  end

  def increment_rate_limiter
    rate_limiter.add("delivery_request")
  end

  # More information around the rate limit can be found here ->
  # https://docs.publishing.service.gov.uk/manual/govuk-notify.html under "GOV.UK Emails".
  def rate_limit_threshold
    per_minute_to_allow_350_per_second = "21000"
    ENV.fetch("DELIVERY_REQUEST_THRESHOLD", per_minute_to_allow_350_per_second).to_i
  end

  def rate_limit_interval
    minute_in_seconds = "60"
    ENV.fetch("DELIVERY_REQUEST_INTERVAL", minute_in_seconds).to_i
  end

  def rate_limiter
    Services.rate_limiter
  end
end
