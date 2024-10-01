class MetricsCollectionWorker::MessageExporter < MetricsCollectionWorker::BaseExporter
  def call
    GovukStatsd.gauge("messages.unprocessed_total", unprocessed_messages)
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
