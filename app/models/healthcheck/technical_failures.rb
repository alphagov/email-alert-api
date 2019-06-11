module Healthcheck
  class TechnicalFailures < DeliveryStatus
    def name
      :technical_failures
    end

    def delivery_status
      4
    end
  end
end
