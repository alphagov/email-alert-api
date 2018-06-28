module Healthcheck
  class ContentChangeHealthcheck
    def name
      :content_changes
    end

    def status
      if critical_content_changes.positive?
        :critical
      elsif warning_content_changes.positive?
        :warning
      else
        :ok
      end
    end

    def details
      {
        critical: critical_content_changes,
        warning: warning_content_changes,
      }
    end

  private

    def critical_content_changes
      @critical_content_changes ||= count_content_changes(critical_latency)
    end

    def warning_content_changes
      @warning_content_changes ||= count_content_changes(warning_latency)
    end

    def count_content_changes(age)
      ContentChange
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
