RSpec.describe MetricsCollectionJob::ContentChangeExporter do
  describe ".call" do
    before do
      create(:content_change, created_at: 122.minutes.ago)
    end

    it "records total number of unprocessed content changes over 120 minutes old" do
      expect(PrometheusMetrics).to receive(:observe).with("total_unprocessed_content_changes", 1)
      described_class.call
    end
  end
end
