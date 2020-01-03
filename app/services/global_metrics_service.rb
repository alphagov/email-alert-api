class GlobalMetricsService
  class << self
    def delivery_attempt_pending_status_total(total)
      gauge("delivery_attempt.pending_status_total", total)
    end

    def delivery_attempt_total(total)
      gauge("delivery_attempt.total", total)
    end

    def critical_subscription_contents_total(total)
      gauge("subscription_contents.critical_total", total)
    end

    def warning_subscription_contents_total(total)
      gauge("subscription_contents.warning_total", total)
    end

  private

    def statsd
      @statsd ||= begin
        statsd = Statsd.new
        statsd.namespace = "govuk.email-alert-api"
        statsd
      end
    end

    def gauge(stat, metric)
      statsd.gauge(stat, metric)
    end
  end
end
