class MetricsCollectionWorker
  include Sidekiq::Worker

  sidekiq_options queue: :cleanup

  def perform
    Metrics::ContentChangeExporter.call
    Metrics::DigestRunExporter.call
    Metrics::MessageExporter.call
    Metrics::StatusUpdateExporter.call
  end
end
