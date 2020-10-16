class DeliveryRequestWorker < ApplicationWorker
  sidekiq_options retry: 9

  sidekiq_retries_exhausted do |msg|
    Email.find(msg["args"].first).update!(status: :failed)
  end

  def perform(email_id, metrics, queue)
    if rate_limit_exceeded?
      logger.warn("Rescheduling email #{email_id} due to exceeding rate limit")
      GovukStatsd.increment("delivery_request_worker.rescheduled")
      DeliveryRequestWorker.set(queue: queue || "delivery_immediate")
                           .perform_in(5.minutes, email_id, metrics, queue)
      return
    end

    increment_rate_limiter

    DeliveryRequestService.call(
      email: Email.find(email_id),
      metrics: parsed_metrics(metrics),
    )
  end

  def self.perform_async_in_queue(email_id, metrics = {}, queue:)
    set(queue: queue).perform_async(email_id, metrics, queue)
  end

private

  def rate_limit_exceeded?
    rate_limiter.exceeded?("delivery_request",
                           threshold: rate_limit_threshold,
                           interval: rate_limit_interval)
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
