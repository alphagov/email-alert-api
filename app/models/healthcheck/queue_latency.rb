module Healthcheck
  class QueueLatency < GovukHealthcheck::SidekiqQueueLatencyCheck
    def critical_threshold(queue:)
      if %i(delivery_immediate_high delivery_immediate).include?(queue)
        immediate_critical_size
      elsif queue == :delivery_digest
        digest_critical_size
      else
        10 * 60 # default to 10 minutes
      end
    end

    def warning_threshold(queue:)
      if %i(delivery_immediate_high delivery_immediate).include?(queue)
        immediate_warning_size
      elsif queue == :delivery_digest
        digest_warning_size
      else
        5 * 60 # default to 5 minutes
      end
    end

    def immediate_critical_size
      ENV.fetch("SIDEKIQ_IMMEDIATE_QUEUE_LATENCY_CRITICAL", 5 * 60).to_i
    end

    def immediate_warning_size
      ENV.fetch("SIDEKIQ_IMMEDIATE_QUEUE_LATENCY_WARNING", 2.5 * 60).to_i
    end

    def digest_critical_size
      ENV.fetch("SIDEKIQ_DIGEST_QUEUE_LATENCY_CRITICAL", 90 * 60).to_i
    end

    def digest_warning_size
      ENV.fetch("SIDEKIQ_DIGEST_QUEUE_LATENCY_CRITICAL", 60 * 60).to_i
    end
  end
end
