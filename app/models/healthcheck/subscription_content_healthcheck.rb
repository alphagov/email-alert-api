module Healthcheck
  class SubscriptionContentHealthcheck
    def name
      :subscription_content
    end

    def status
      if count_subscription_contents(critical_latency).positive?
        :critical
      elsif count_subscription_contents(warning_latency).positive?
        :warning
      else
        :ok
      end
    end

    def details
      {
        critical: count_subscription_contents(critical_latency),
        warning: count_subscription_contents(warning_latency),
      }
    end

  private

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
      1.minute
    end

    def warning_latency
      30.seconds
    end
  end
end
