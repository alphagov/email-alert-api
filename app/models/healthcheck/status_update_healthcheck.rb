module Healthcheck
  class StatusUpdateHealthcheck
    def name
      :status_update
    end

    def status
      return :ok unless expect_status_update_callbacks?

      if proportion_pending >= 0.2
        :critical
      elsif proportion_pending >= 0.1
        :warning
      else
        :ok
      end
    end

    def details
      {
        totals: totals,
        pending: proportion_pending,
        done: proportion_done,
      }
    end

  private

    def totals
      DeliveryAttempt
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

    def proportion_pending
      return 0 if total.zero?
      total_pending.to_f / total.to_f
    end

    def proportion_done
      return 1 if total.zero?
      total_done.to_f / total.to_f
    end

    def expect_status_update_callbacks?
      EmailAlertAPI.config.email_service.fetch(:expect_status_update_callbacks)
    end
  end
end
