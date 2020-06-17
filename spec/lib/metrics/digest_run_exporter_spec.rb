RSpec.describe Metrics::DigestRunExporter do
  describe ".call" do
    let(:statsd) { double }

    before do
      create(:digest_run, created_at: 61.minutes.ago)
      create(:digest_run, created_at: 21.minutes.ago)
      allow(GlobalMetricsService.send(:statsd)).to receive(:gauge)
    end

    it "records number of unprocessed digest runs over 1 hour old (critical)" do
      expect(GlobalMetricsService).to receive(:critical_digest_runs_total).with(1)
      described_class.call
    end

    it "records number of unprocessed digest runs over 20 minutes old (warning)" do
      expect(GlobalMetricsService).to receive(:warning_digest_runs_total).with(2)
      described_class.call
    end

    it "sends the correct values to statsd" do
      expect(GlobalMetricsService.send(:statsd)).to receive(:gauge)
        .with("digest_runs.critical_total", 1)
      expect(GlobalMetricsService.send(:statsd)).to receive(:gauge)
        .with("digest_runs.warning_total", 2)

      described_class.call
    end
  end
end
