class Metrics::DigestRunExporter < Metrics::BaseExporter
  def call
    GlobalMetricsService.critical_digest_runs_total(critical_digest_runs)
    GlobalMetricsService.warning_digest_runs_total(warning_digest_runs)
  end

private

  def critical_digest_runs
    @critical_digest_runs ||= count_digest_runs(critical_latency)
  end

  def warning_digest_runs
    @warning_digest_runs ||= count_digest_runs(warning_latency)
  end

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
