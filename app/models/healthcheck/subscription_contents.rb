module Healthcheck
  class SubscriptionContents
    def name
      :subscription_contents
    end

    def status
      if critical_subscription_contents.positive?
        :critical
      elsif warning_subscription_contents.positive?
        :warning
      else
        :ok
      end
    end

    def details
      {
        critical: critical_subscription_contents,
        warning: warning_subscription_contents,
      }
    end

    def message
      <<~MESSAGE
        #{critical_subscription_contents} created over #{critical_latency} seconds ago.
        #{warning_subscription_contents} created over #{warning_latency} seconds ago.
      MESSAGE
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
        group_sql = ActiveRecord::Base::sanitize_sql([
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
      is_scheduled_publishing_time? ? 45.minutes : 15.minutes
    end

    def warning_latency
      is_scheduled_publishing_time? ? 30.minutes : 10.minutes
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
end
