module Healthcheck
  class TechnicalFailureHealthcheck
    def name
      :technical_failure
    end

    def status
      return :ok unless expect_status_update_callbacks?

      if proportion_failing >= 0.1
        :critical
      elsif proportion_failing >= 0.05
        :warning
      else
        :ok
      end
    end

    def details
      {
        totals: totals,
        failing: proportion_failing,
        other: proportion_other,
      }
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

    def proportion_failing
      return 0 if total.zero?
      total_failing.to_f / total.to_f
    end

    def proportion_other
      return 1 if total.zero?
      total_other.to_f / total.to_f
    end

    def expect_status_update_callbacks?
      EmailAlertAPI.config.email_service.fetch(:expect_status_update_callbacks)
    end
  end
end
