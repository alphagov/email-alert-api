module Healthcheck
  class QueueSizeHealthcheck
    def name
      :queue_size
    end

    def status
      if queue_sizes.any? { |s| s >= critical_size }
        :critical
      elsif queue_sizes.any? { |s| s >= warning_size }
        :warning
      else
        :ok
      end
    end

    def details
      { queues: queues }
    end

  private

    def queue_sizes
      queues.values
    end

    def queues
      Sidekiq::Stats.new.queues
    end

    def critical_size
      ENV.fetch("SIDEKIQ_QUEUE_SIZE_CRITICAL", 100000).to_i
    end

    def warning_size
      ENV.fetch("SIDEKIQ_QUEUE_SIZE_WARNING", 75000).to_i
    end
  end
end
