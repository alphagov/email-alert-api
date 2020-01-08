RSpec.describe ContentChangesWorker do
  describe ".perform" do
    shared_examples "tests for critical and warning states" do
      context "find content changes from last 15 minutes" do
        let(:statsd) { double }

        before do
          create(:content_change, created_at: 11.minutes_ago)
          create(:content_change, created_at: 6.minutes_ago)
          allow(GlobalMetricsService.send(:statsd)).to receive(:gauge)
        end

        it "records number of unprocessed content changes over 10 minutes old (critical)" do
          expect(GlobalMetricsService).to receive(:critical_content_changes_total).with(1)
          described_class.new.perform
        end

        it "records number of unprocessed content changes over 5 minutes old (warning)" do
          expect(GlobalMetricsService).to receive(:warning_content_changes_total).with(2)
          described_class.new.perform
        end

        it "sends the correct values to statsd" do
          expect(GlobalMetricsService.send(:statsd)).to receive(:gauge)
            .with("content_changes.critical_total", 1)
          expect(GlobalMetricsService.send(:statsd)).to receive(:gauge)
            .with("content_changes.warning_total", 2)

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
