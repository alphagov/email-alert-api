RSpec.describe MetricsCollectionJob::MessageExporter do
  describe ".call" do
    before do
      3.times { create(:message, created_at: 122.minutes.ago) }
    end

    it "records total number of unprocessed messages over 120 minutes old" do
      expect(PrometheusMetrics).to receive(:observe).with("total_unprocessed_messages", 3)
      described_class.call
    end
  end
end
