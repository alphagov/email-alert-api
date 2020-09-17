class MetricsCollectionWorker
  include Sidekiq::Worker

  def perform
    ContentChangeExporter.call
    DigestRunExporter.call
    MessageExporter.call
  end
end
