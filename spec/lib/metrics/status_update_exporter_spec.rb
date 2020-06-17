RSpec.describe Metrics::StatusUpdateExporter do
  describe ".call" do
    let(:statsd) { double }

    before do
      3.times { create(:delivery_attempt, status: 0, created_at: 40.minutes.ago) }
      2.times { create(:delivery_attempt, status: 1, created_at: 20.minutes.ago) }
      allow(GlobalMetricsService.send(:statsd)).to receive(:gauge)
    end

    it "records a metric for the total number of pending delivery attempts" do
      expect(GlobalMetricsService).to receive(:delivery_attempt_pending_status_total).with(3)
      described_class.call
    end

    it "records a metric for the total number of delivery attempts" do
      expect(GlobalMetricsService).to receive(:delivery_attempt_total).with(5)
      described_class.call
    end

    it "sends the correct values to statsd" do
      expect(GlobalMetricsService.send(:statsd)).to receive(:gauge)
      .with("delivery_attempt.total", 5)
      expect(GlobalMetricsService.send(:statsd)).to receive(:gauge)
      .with("delivery_attempt.pending_status_total", 3)

      described_class.call
    end
  end
end
