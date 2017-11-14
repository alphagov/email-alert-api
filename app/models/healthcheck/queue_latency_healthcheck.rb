class Healthcheck
  class QueueLatencyHealthcheck
    def name
      :queue_latency
    end

    def status
      if queue_latencies.any? { |s| s >= critical_size }
        :critical
      elsif queue_latencies.any? { |s| s >= warning_size }
        :warning
      else
        :ok
      end
    end

    def details
      { queues: queues }
    end

  private

    def queue_latencies
      queues.values
    end

    def queues
      @queues ||= queue_names.each.with_object({}) do |name, hash|
        hash[name] = latency_for(name)
      end
    end

    def latency_for(name)
      Sidekiq::Queue.new(name).latency
    end

    def queue_names
      @queues ||= Sidekiq::Stats.new.queues.keys
    end

    def critical_size
      ENV.fetch("SIDEKIQ_QUEUE_LATENCY_CRITICAL", 10).to_i
    end

    def warning_size
      ENV.fetch("SIDEKIQ_QUEUE_LATENCY_WARNING", 5).to_i
    end
  end
end
