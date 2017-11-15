class Healthcheck
  class DatabaseHealthcheck
    def name
      :database
    end

    def status
      ActiveRecord::Base.connected? ? :ok : :critical
    end

    def details
      {}
    end
  end
end
