class Healthcheck
  class GovdeliveryHealthcheck
    def name
      :govdelivery
    end

    def status
      ping_status == 200 ? :ok : :critical
    end

    def details
      { ping_status: ping_status }
    end

  private

    def ping_status
      @ping_status ||= Services.gov_delivery.ping.status
    end
  end
end
