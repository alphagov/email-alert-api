module Healthcheck
  class QueueLatency
    def name
      :queue_latency
    end

    def status
      if queues.values.any? { |queue| queue.fetch(:critical) }
        :critical
      elsif queues.values.any? { |queue| queue.fetch(:warning) }
        :warning
      else
        :ok
      end
    end

    def details
      { queues: queues }
    end

  private

    def queues
      @queues ||= thresholds_for_queues.each_with_object({}) do |(name, threshold), hash|
        latency = latency_for(name)
        critical = latency > threshold.fetch(:critical)
        warning = latency > threshold.fetch(:warning)
        hash[name] = { latency: latency, critical: critical, warning: warning }
      end
    end

    def latency_for(name)
      Sidekiq::Queue.new(name).latency
    end

    def thresholds_for_queues
      {
        delivery_immediate_high: { critical: immediate_critical_size, warning: immediate_warning_size },
        delivery_immediate: { critical: immediate_critical_size, warning: immediate_warning_size },
        delivery_digest: { critical: digest_critical_size, warning: digest_warning_size },
      }
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
