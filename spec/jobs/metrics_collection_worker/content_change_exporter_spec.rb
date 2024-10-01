RSpec.describe MetricsCollectionWorker::ContentChangeExporter do
  describe ".call" do
    let(:statsd) { double }

    before do
      create(:content_change, created_at: 122.minutes.ago)
      allow(GovukStatsd).to receive(:gauge)
    end

    it "records total number of unprocessed content changes over 120 minutes old" do
      expect(GovukStatsd).to receive(:gauge).with("content_changes.unprocessed_total", 1)
      described_class.call
    end
  end
end
