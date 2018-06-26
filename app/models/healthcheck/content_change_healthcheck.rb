module Healthcheck
  class ContentChangeHealthcheck
    def name
      :content_change
    end

    def status
      if count_content_changes(critical_latency).positive?
        :critical
      elsif count_content_changes(warning_latency).positive?
        :warning
      else
        :ok
      end
    end

    def details
      {
        critical: count_content_changes(critical_latency),
        warning: count_content_changes(warning_latency),
      }
    end

  private

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
