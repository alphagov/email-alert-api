class MetricsCollectionJob < ApplicationJob
  def perform
    ContentChangeExporter.call
    DigestRunExporter.call
    MessageExporter.call
  end
end
