RSpec.describe StatusUpdateWorker do
  describe ".perform" do
    context "find delivery attempts created within the last hour" do
      let(:statsd) { double }

      before do
        3.times { create(:delivery_attempt, status: 0, created_at: 40.minutes.ago) }
        2.times { create(:delivery_attempt, status: 1, created_at: 20.minutes.ago) }
        allow(GlobalMetricsService.send(:statsd)).to receive(:gauge)
      end

      it "records a metric for the total number of pending delivery attempts" do
        expect(GlobalMetricsService).to receive(:delivery_attempt_pending_status_total).with(3)
        described_class.new.perform
      end

      it "records a metric for the total number of delivery attempts" do
        expect(GlobalMetricsService).to receive(:delivery_attempt_total).with(5)
        described_class.new.perform
      end

      it "sends the correct values to statsd" do
        expect(GlobalMetricsService.send(:statsd)).to receive(:gauge)
        .with("delivery_attempt.total", 5)
        expect(GlobalMetricsService.send(:statsd)).to receive(:gauge)
        .with("delivery_attempt.pending_status_total", 3)

        described_class.new.perform
      end
    end
  end

  describe ".perform_async" do
    before do
      Sidekiq::Testing.fake! do
        described_class.perform_async
      end
    end

    it "gets put on the low priority 'cleanup' queue" do
      expect(Sidekiq::Queues["cleanup"].size).to eq(2)
    end
  end
end
