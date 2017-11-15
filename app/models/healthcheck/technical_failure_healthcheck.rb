class Healthcheck
  class TechnicalFailureHealthcheck
    def name
      :technical_failure
    end

    def status
      if failures_since(1.hour.ago).exists?
        :critical
      elsif failures_since(1.day.ago).exists?
        :warning
      else
        :ok
      end
    end

    def details
      1.upto(24).each_with_object({}) do |n, hash|
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
  end
end
