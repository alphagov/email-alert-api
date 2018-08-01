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
      @critical_subscription_contents ||= count_subscription_contents(critical_latency)
    end

    def warning_subscription_contents
      @warning_subscription_contents ||= count_subscription_contents(warning_latency)
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
      10.minutes
    end

    def warning_latency
      5.minutes
    end
  end
end
