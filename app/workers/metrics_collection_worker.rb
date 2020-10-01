class MetricsCollectionWorker < ApplicationWorker
  def perform
    ContentChangeExporter.call
    DigestRunExporter.call
    MessageExporter.call
  end
end
