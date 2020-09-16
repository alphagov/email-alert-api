RSpec.describe MetricsCollectionWorker do
  describe ".perform" do
    it "delegates to collect metrics" do
      expect(MetricsCollectionWorker::ContentChangeExporter).to receive(:call)
      expect(MetricsCollectionWorker::DigestRunExporter).to receive(:call)
      expect(MetricsCollectionWorker::MessageExporter).to receive(:call)

      subject.perform
    end
  end
end
