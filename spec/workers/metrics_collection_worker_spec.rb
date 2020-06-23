RSpec.describe MetricsCollectionWorker do
  describe ".perform" do
    it "delegates to collect metrics" do
      expect(Metrics::ContentChangeExporter).to receive(:call)
      expect(Metrics::DigestRunExporter).to receive(:call)
      expect(Metrics::MessageExporter).to receive(:call)
      expect(Metrics::StatusUpdateExporter).to receive(:call)

      subject.perform
    end
  end
end
