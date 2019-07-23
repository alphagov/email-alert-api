module Healthcheck
  class SubscriptionContents
    def name
      :subscription_contents
    end

    def status
      if critical_subscription_contents.positive?
        :critical
      else
        :ok
      end
    end

    def details
      {
        critical: critical_subscription_contents,
      }
    end

    def message
      <<~MESSAGE
        #{critical_subscription_contents} created over #{critical_latency} seconds ago.
      MESSAGE
    end

  private

    def critical_subscription_contents
      @critical_subscription_contents ||= count_subscription_contents(critical_latency)
    end

    def count_subscription_contents(age)
      # The `merge(Subscription.active)` check is because there is a
      # race condition in email generation: if someone unsubscribes
      # after the `ContentChange` has been processed but before the
      # generated `SubscriptionContent`s have been, then those
      # `SubscriptionContent`s will never get an email associated with
      # them - this is the correct behaviour, we don't want to email
      # people who have unsubscribed.
      SubscriptionContent
        .where("subscription_contents.created_at < ?", age.ago)
        .where(email: nil)
        .joins(:subscription)
        .merge(Subscription.active)
        .count
    end

    def critical_latency
      is_scheduled_publishing_time? ? 15.minutes : 5.minutes
    end

    # There's a lot of scheduled publishing at 09:30 UK time, so we
    # want larger thresholds around then.
    def is_scheduled_publishing_time?
      @is_scheduled_publishing_time ||= begin
        now = Time.zone.now
        begun = Time.zone.parse("09:30") <= now
        ended = Time.zone.parse("10:30") <= now
        begun && !ended
      end
    end
  end
end
