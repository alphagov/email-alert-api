module Healthcheck
  class TechnicalFailures < GovukHealthcheck::ThresholdCheck
    def name
      :technical_failures
    end

    def value
      return 0 if total.zero?
      total_failing.to_f / total.to_f
    end

    def critical_threshold
      0.1
    end

    def warning_threshold
      0.05
    end

    def enabled?
      EmailAlertAPI.config.email_service.fetch(:expect_status_update_callbacks)
    end

  private

    def totals
      @totals ||= DeliveryAttempt
        .where("created_at > ?", 1.hour.ago)
        .group("CASE WHEN status = 4 THEN 'failing' ELSE 'other' END")
        .count
    end

    def total_failing
      totals.fetch("failing", 0)
    end

    def total_other
      totals.fetch("other", 0)
    end

    def total
      total_failing + total_other
    end
  end
end
