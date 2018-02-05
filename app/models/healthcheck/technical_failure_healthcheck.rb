class Healthcheck
  class TechnicalFailureHealthcheck
    def name
      :technical_failure
    end

    def status
      return :ok unless expect_status_update_callbacks?

      if failures_since(1.hour).exists?
        :critical
      elsif failures_since(24.hours).exists?
        :warning
      else
        :ok
      end
    end

    def details
      [1, 12, 24].each_with_object({}) do |n, hash|
        hash[:"last_#{n}_hours"] = failures_since(n.hours).count
      end
    end

  private

    def failures_since(hours)
      @failures_since_cache ||= {}
      @failures_since_cache[hours] ||= begin
        DeliveryAttempt
          .latest_per_email
          .where(status: :technical_failure)
          .where("updated_at > ?", hours.ago)
      end
    end

    def expect_status_update_callbacks?
      EmailAlertAPI.config.email_service.fetch(:expect_status_update_callbacks)
    end
  end
end
