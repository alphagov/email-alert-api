class MetricsCollectionJob::DigestRunExporter < MetricsCollectionJob::BaseExporter
  def call
    critical_digest_runs = DigestRun.where("created_at < ?", 2.hours.ago)
                                    .where(completed_at: nil)
                                    .count

    PrometheusMetrics.observe("total_unprocessed_digest_runs", critical_digest_runs)
  end
end
