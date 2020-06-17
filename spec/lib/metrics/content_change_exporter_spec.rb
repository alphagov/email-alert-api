RSpec.describe Metrics::ContentChangeExporter do
  describe ".call" do
    let(:statsd) { double }

    before do
      create(:content_change, created_at: 11.minutes.ago)
      create(:content_change, created_at: 6.minutes.ago)
      allow(GlobalMetricsService.send(:statsd)).to receive(:gauge)
    end

    it "records number of unprocessed content changes over 10 minutes old (critical)" do
      expect(GlobalMetricsService).to receive(:critical_content_changes_total).with(1)
      described_class.call
    end

    it "records number of unprocessed content changes over 5 minutes old (warning)" do
      expect(GlobalMetricsService).to receive(:warning_content_changes_total).with(2)
      described_class.call
    end

    it "sends the correct values to statsd" do
      expect(GlobalMetricsService.send(:statsd)).to receive(:gauge)
        .with("content_changes.critical_total", 1)
      expect(GlobalMetricsService.send(:statsd)).to receive(:gauge)
        .with("content_changes.warning_total", 2)

      described_class.call
    end
  end
end
