class MetricsCollectionWorker::DigestRunExporter < MetricsCollectionWorker::BaseExporter
  def call
    GovukStatsd.gauge("digest_runs.critical_total", critical_digest_runs)
  end

private

  def critical_digest_runs
    @critical_digest_runs ||= count_digest_runs(critical_latency)
  end

  def count_digest_runs(age)
    DigestRun
      .where("created_at < ?", age.ago)
      .where(completed_at: nil)
      .count
  end

  def critical_latency
    2.hours
  end
end
