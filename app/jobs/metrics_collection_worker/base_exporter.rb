class MetricsCollectionWorker::BaseExporter
  def self.call
    new.call
  end

  private_class_method :new
end
