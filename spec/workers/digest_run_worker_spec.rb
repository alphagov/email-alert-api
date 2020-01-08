RSpec.describe DigestRunWorker do
  describe ".perform" do
    shared_examples "tests for critical and warning states" do
      context "find incomplete digest runs" do
        let(:statsd) { double }

        before do
          create(:digest_run, created_at: 61.minutes_ago)
          create(:digest_run, created_at: 21.minutes_ago)
          allow(GlobalMetricsService.send(:statsd)).to receive(:gauge)
        end

        it "records number of unprocessed digest runs over 1 hour old (critical)" do
          expect(GlobalMetricsService).to receive(:critical_digest_runs_total).with(1)
          described_class.new.perform
        end

        it "records number of unprocessed digest runs over 20 minutes old (warning)" do
          expect(GlobalMetricsService).to receive(:warning_digest_runs_total).with(2)
          described_class.new.perform
        end

        it "sends the correct values to statsd" do
          expect(GlobalMetricsService.send(:statsd)).to receive(:gauge)
            .with("digest_runs.critical_total", 1)
          expect(GlobalMetricsService.send(:statsd)).to receive(:gauge)
            .with("digest_runs.warning_total", 2)

          described_class.new.perform
        end
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
      expect(Sidekiq::Queues["cleanup"].size).to eq(1)
    end
  end
end
