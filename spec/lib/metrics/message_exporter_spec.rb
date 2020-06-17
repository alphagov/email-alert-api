RSpec.describe Metrics::MessageExporter do
  describe ".call" do
    let(:statsd) { double }

    before do
      3.times { create(:message, processed_at: nil, created_at: 10.minutes.ago) }
      2.times { create(:message, processed_at: nil, created_at: 5.minutes.ago) }
      allow(GlobalMetricsService.send(:statsd)).to receive(:gauge)
    end

    it "records a metric for the total number of unprocessed messages created
    over 10 minutes ago (critical)" do
      expect(GlobalMetricsService).to receive(:critical_messages_total).with(3)
      described_class.call
    end

    it "records a metric for the total number of unprocessed messages created
    over 5 minutes ago (warning)" do
      expect(GlobalMetricsService).to receive(:warning_messages_total).with(5)
      described_class.call
    end

    it "sends the correct values to statsd" do
      expect(GlobalMetricsService.send(:statsd)).to receive(:gauge)
      .with("messages.warning_total", 5)
      expect(GlobalMetricsService.send(:statsd)).to receive(:gauge)
      .with("messages.critical_total", 3)

      described_class.call
    end
  end
end
