module Healthcheck
  class Messages
    def name
      :messages
    end

    def status
      if critical_messages.positive?
        :critical
      elsif warning_messages.positive?
        :warning
      else
        :ok
      end
    end

    def details
      {
        critical: critical_messages,
        warning: warning_messages,
      }
    end

  private

    def critical_messages
      @critical_messages ||= count_messages(critical_latency)
    end

    def warning_messages
      @warning_messages ||= count_messages(warning_latency)
    end

    def count_messages(age)
      Message
        .where("created_at < ?", age.ago)
        .where(processed_at: nil)
        .count
    end

    def critical_latency
      10.minutes
    end

    def warning_latency
      5.minutes
    end
  end
end
