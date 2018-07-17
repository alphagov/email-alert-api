module Healthcheck
  class QueueSize < GovukHealthcheck::SidekiqQueueSizeCheck
    def critical_threshold(*)
      ENV.fetch("SIDEKIQ_QUEUE_SIZE_CRITICAL", 100000).to_i
    end

    def warning_threshold(*)
      ENV.fetch("SIDEKIQ_QUEUE_SIZE_WARNING", 75000).to_i
    end
  end
end
