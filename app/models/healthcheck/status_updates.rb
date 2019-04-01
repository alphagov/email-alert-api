module Healthcheck
  class StatusUpdates < GovukHealthcheck::ThresholdCheck
    def name
      :status_updates
    end

    def value
      return 0 if total.zero?

      total_pending.to_f / total.to_f
    end

    def critical_threshold
      0.25
    end

    def warning_threshold
      0.166
    end

    def enabled?
      EmailAlertAPI.config.email_service.fetch(:expect_status_update_callbacks)
    end

  private

    def totals
      @totals ||= DeliveryAttempt
        .where("created_at > ? AND created_at <= ?", (1.hour + 10.minutes).ago, 10.minutes.ago)
        .group("CASE WHEN status = 0 THEN 'pending' ELSE 'done' END")
        .count
    end

    def total_pending
      totals.fetch("pending", 0)
    end

    def total_done
      totals.fetch("done", 0)
    end

    def total
      total_pending + total_done
    end
  end
end
