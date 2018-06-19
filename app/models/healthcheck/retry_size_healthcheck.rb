module Healthcheck
  class RetrySizeHealthcheck
    def name
      :retry_size
    end

    def status
      if retry_size >= critical_size
        :critical
      elsif retry_size >= warning_size
        :warning
      else
        :ok
      end
    end

    def details
      { retry_size: retry_size }
    end

  private

    def retry_size
      @retry_size ||= Sidekiq::Stats.new.retry_size
    end

    def critical_size
      ENV.fetch("SIDEKIQ_RETRY_SIZE_CRITICAL", 50000).to_i
    end

    def warning_size
      ENV.fetch("SIDEKIQ_RETRY_SIZE_WARNING", 40000).to_i
    end
  end
end
