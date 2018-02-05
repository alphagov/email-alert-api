class Healthcheck
  class StatusUpdateHealthcheck
    NOTIFY_DELAY = 72 # hours

    def name
      :status_update
    end

    def status
      return :ok unless expect_status_update_callbacks?

      if sending_after(critical_time.ago).exists?
        :critical
      elsif sending_after(warning_time.ago).exists?
        :warning
      else
        :ok
      end
    end

    def details
      from = NOTIFY_DELAY
      to = from + 36

      (from..to).step(12).with_object({}) do |n, hash|
        hash[:"older_than_#{n}_hours"] = sending_after(n.hours.ago).count
      end
    end

  private

    def sending_after(datetime)
      DeliveryAttempt
        .latest_per_email
        .where(status: :sending)
        .where("updated_at < ?", datetime)
    end

    def critical_time
      warning_time + 2.hours
    end

    # Both systems use queueing, so build in some tolerance.
    def warning_time
      NOTIFY_DELAY.hours + 10.minutes
    end

    def expect_status_update_callbacks?
      EmailAlertAPI.config.email_service.fetch(:expect_status_update_callbacks)
    end
  end
end
