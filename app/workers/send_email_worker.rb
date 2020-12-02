class SendEmailWorker < ApplicationWorker
  # More information around the rate limit can be found here ->
  # https://docs.publishing.service.gov.uk/manual/govuk-notify.html under "GOV.UK Emails".
  RATE_LIMIT_THRESHOLD = 21_600 # max requests in a minute, equates to 350 a second
  RATE_LIMIT_INTERVAL = 60

  sidekiq_options lock: :until_executing,
                  unique_across_queues: true,
                  unique_args: :uniqueness_with, # in upcoming version 7 of sidekiq-unique-jobs, :unique_args is replaced with :lock_args
                  on_conflict: :log,
                  retry_count: 9

  def self.uniqueness_with(args)
    [args.first]
  end

  def perform(email_id, metrics, queue)
    if rate_limit_exceeded?
      logger.warn("Rescheduling email #{email_id} due to exceeding rate limit")
      SendEmailWorker.set(queue: queue || "send_email_immediate")
                           .perform_in(5.minutes, email_id, metrics, queue)
      return
    end

    ActiveRecord::Base.transaction do
      email = Email.lock.find_by(id: email_id, status: :pending)
      return unless email

      increment_rate_limiter
      SendEmailService.call(email: email, metrics: parsed_metrics(metrics))
    end
  end

  def self.perform_async_in_queue(email_id, metrics = {}, queue:)
    set(queue: queue).perform_async(email_id, metrics, queue)
  end

private

  def rate_limit_exceeded?
    Services.rate_limiter.exceeded?("requests",
                                    threshold: RATE_LIMIT_THRESHOLD,
                                    interval: RATE_LIMIT_INTERVAL)
  end

  # Sidekiq uses JSON for a workers arguments, so richer objects are not
  # available. This converts the scalar values to objects.
  def parsed_metrics(metrics)
    content_change_created_at = metrics["content_change_created_at"]
      &.then { |t| Time.zone.iso8601(t) }

    { content_change_created_at: content_change_created_at }.compact
  end

  def increment_rate_limiter
    Services.rate_limiter.add("requests")
  end
end
