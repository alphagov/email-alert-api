class MetricsCollectionWorker::DigestRunExporter < MetricsCollectionWorker::BaseExporter
  def call
    critical_digest_runs = DigestRun.where("created_at < ?", 2.hours.ago)
                                    .where(completed_at: nil)
                                    .count

    GovukStatsd.gauge("digest_runs.critical_total", critical_digest_runs)
  end
end
