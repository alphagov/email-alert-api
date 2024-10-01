class MetricsCollectionWorker::ContentChangeExporter < MetricsCollectionWorker::BaseExporter
  def call
    GovukStatsd.gauge("content_changes.unprocessed_total", unprocessed_content_changes)
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
