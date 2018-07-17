module Healthcheck
  class RetrySize < GovukHealthcheck::SidekiqRetrySizeCheck
    def critical_threshold
      ENV.fetch("SIDEKIQ_RETRY_SIZE_CRITICAL", 50000).to_i
    end

    def warning_threshold
      ENV.fetch("SIDEKIQ_RETRY_SIZE_WARNING", 40000).to_i
    end
  end
end
