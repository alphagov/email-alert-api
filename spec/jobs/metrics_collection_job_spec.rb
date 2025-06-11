RSpec.describe MetricsCollectionJob do
  describe ".perform" do
    it "delegates to collect metrics" do
      expect(MetricsCollectionJob::ContentChangeExporter).to receive(:call)
      expect(MetricsCollectionJob::DigestRunExporter).to receive(:call)
      expect(MetricsCollectionJob::MessageExporter).to receive(:call)

      subject.perform
    end
  end
end
