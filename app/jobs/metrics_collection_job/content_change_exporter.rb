class MetricsCollectionJob::ContentChangeExporter < MetricsCollectionJob::BaseExporter
  def call
    PrometheusMetrics.observe("total_unprocessed_content_changes", unprocessed_content_changes)
  end

private

  def unprocessed_content_changes
    ContentChange
      .where("created_at < ?", unprocessed_latency.ago)
      .where(processed_at: nil)
      .count
  end

  def unprocessed_latency
    120.minutes
  end
end
