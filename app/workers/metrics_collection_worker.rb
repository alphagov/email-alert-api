class MetricsCollectionWorker
  include Sidekiq::Worker

  def perform
    Metrics::ContentChangeExporter.call
    Metrics::DigestRunExporter.call
    Metrics::MessageExporter.call
    Metrics::StatusUpdateExporter.call
  end
end
