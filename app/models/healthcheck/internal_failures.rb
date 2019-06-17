module Healthcheck
  class InternalFailures < DeliveryStatus
    def name
      :internal_failures
    end

    def delivery_status
      5
    end
  end
end
