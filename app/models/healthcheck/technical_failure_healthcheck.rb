class Healthcheck
  class TechnicalFailureHealthcheck
    def name
      :technical_failure
    end

    def status
      return :ok unless expect_status_update_callbacks?

      if failures_since(1.hour.ago).exists?
        :critical
      elsif failures_since(1.day.ago).exists?
        :warning
      else
        :ok
      end
    end

    def details
      [1, 6, 12, 24].each_with_object({}) do |n, hash|
        hash[:"last_#{n}_hours"] = failures_since(n.hours.ago).count
      end
    end

  private

    def failures_since(datetime)
      DeliveryAttempt
        .latest_per_email
        .where(status: :technical_failure)
        .where("updated_at > ?", datetime)
    end

    def expect_status_update_callbacks?
      EmailAlertAPI.config.email_service.fetch(:expect_status_update_callbacks)
    end
  end
end
