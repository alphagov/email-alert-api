module Healthcheck
  class DeliveryStatus < GovukHealthcheck::ThresholdCheck
    def value
      return 0 if total.zero?

      total_failing.to_f / total
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

    def delivery_status
      raise "This method must be overridden to be the status value."
    end

  private

    def totals
      @totals ||= DeliveryAttempt
        .where("created_at > ?", 1.hour.ago)
        .group("CASE WHEN status = #{ActiveRecord::Base.connection.quote(delivery_status)} THEN 'failing' ELSE 'other' END")
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
