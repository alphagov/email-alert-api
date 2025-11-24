class MetricsCollectionJob::MessageExporter < MetricsCollectionJob::BaseExporter
  def call
    PrometheusMetrics.observe("total_unprocessed_messages", unprocessed_messages)
  end

private

  def unprocessed_messages
    Message
    .where("created_at < ?", unprocessed_latency.ago)
    .where(processed_at: nil)
    .count
  end

  def unprocessed_latency
    120.minutes
  end
end
