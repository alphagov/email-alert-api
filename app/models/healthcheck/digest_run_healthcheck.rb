module Healthcheck
  class DigestRunHealthcheck
    def name
      :digest_runs
    end

    def status
      if count_digest_runs(critical_latency).positive?
        :critical
      elsif count_digest_runs(warning_latency).positive?
        :warning
      else
        :ok
      end
    end

    def details
      {
        critical: count_digest_runs(critical_latency),
        warning: count_digest_runs(warning_latency),
      }
    end

  private

    def count_digest_runs(age)
      DigestRun
        .where("created_at < ?", age.ago)
        .where(completed_at: nil)
        .count
    end

    def critical_latency
      1.hour
    end

    def warning_latency
      20.minutes
    end
  end
end
