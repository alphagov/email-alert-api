RSpec.describe MetricsCollectionWorker::MessageExporter do
  describe ".call" do
    let(:statsd) { double }

    before do
      3.times { create(:message, created_at: 122.minutes.ago) }
      allow(GovukStatsd).to receive(:gauge)
    end

    it "records total number of unprocessed messages over 120 minutes old" do
      expect(GovukStatsd).to receive(:gauge).with("messages.unprocessed_total", 3)
      described_class.call
    end
  end
end
