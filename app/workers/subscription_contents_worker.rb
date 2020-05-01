class SubscriptionContentsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :cleanup

  def perform
    GlobalMetricsService.critical_subscription_contents_total(critical_subscription_contents)
    GlobalMetricsService.warning_subscription_contents_total(warning_subscription_contents)
  end

private

  def critical_subscription_contents
    @critical_subscription_contents ||= count_subscription_contents.fetch(:critical)
  end

  def warning_subscription_contents
    @warning_subscription_contents ||= count_subscription_contents.fetch(:warning)
  end

  def count_subscription_contents
    @count_subscription_contents ||= begin
      group_sql = ActiveRecord::Base.sanitize_sql([
        "CASE WHEN subscription_contents.created_at < ? THEN 'critical' ELSE 'warning' END",
        critical_latency.ago,
      ])

      # The `merge(Subscription.active)` check is because there is a
      # race condition in email generation: if someone unsubscribes
      # after the `ContentChange` has been processed but before the
      # generated `SubscriptionContent`s have been, then those
      # `SubscriptionContent`s will never get an email associated with
      # them - this is the correct behaviour, we don't want to email
      # people who have unsubscribed.
      counts = SubscriptionContent
      .where(email: nil)
      .joins(:subscription)
      .merge(Subscription.active)
      .where("subscription_contents.created_at < ?", warning_latency.ago)
      .group(group_sql)
      .count

      warning = counts.fetch("warning", 0)
      critical = counts.fetch("critical", 0)

      { warning: warning + critical, critical: critical }
    end
  end

  def critical_latency
    is_scheduled_publishing_time? ? 50.minutes : 15.minutes
  end

  def warning_latency
    is_scheduled_publishing_time? ? 35.minutes : 10.minutes
  end

  # There's a lot of scheduled publishing at 09:30 UK time, so we
  # want larger thresholds around then.
  def is_scheduled_publishing_time?
    @is_scheduled_publishing_time ||= begin
      now = Time.zone.now
      SCHEDULED_PUBLISHING_TIMES.any? { |min, max| now.between?(min, max) }
    end
  end

  SCHEDULED_PUBLISHING_TIMES = [
    [Time.zone.parse("09:30"), Time.zone.parse("11:00")],
    [Time.zone.parse("12:30"), Time.zone.parse("13:30")],
  ].freeze
end
