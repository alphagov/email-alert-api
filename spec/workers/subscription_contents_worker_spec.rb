RSpec.describe SubscriptionContentsWorker do
  describe ".perform" do
    shared_examples "tests for critical and warning states" do
      context "find subscription contents created within the last hour" do
        let(:statsd) { double }

        before do
          create(:subscription_content, created_at: 51.minutes.ago)
          create(:subscription_content, created_at: 36.minutes.ago)
          allow(GlobalMetricsService.send(:statsd)).to receive(:gauge)
        end

        it "records a metric for the number of subscription contents created over
        50 minutes ago (critical)" do
          expect(GlobalMetricsService).to receive(:critical_subscription_contents_total).with(1)
          described_class.new.perform
        end

        it "records a metric for the number of subscription contents created over
        35 minutes ago (warning)" do
          expect(GlobalMetricsService).to receive(:warning_subscription_contents_total).with(2)
          described_class.new.perform
        end

        it "sends the correct values to statsd" do
          expect(GlobalMetricsService.send(:statsd)).to receive(:gauge)
          .with("subscription_contents.critical_total", 1)
          expect(GlobalMetricsService.send(:statsd)).to receive(:gauge)
          .with("subscription_contents.warning_total", 2)

          described_class.new.perform
        end
      end
    end

    context "between 09:30 and 11:00" do
      around do |example|
        Timecop.freeze("10:00") { example.run }
      end

      include_examples "tests for critical and warning states"
    end

    context "between 12:30 and 13:30" do
      around do |example|
        Timecop.freeze("13:00") { example.run }
      end

      include_examples "tests for critical and warning states"
    end


    context "when not scheduled publishing time" do
      let(:statsd) { double }

      before do
        create(:subscription_content, created_at: 21.minutes.ago)
        create(:subscription_content, created_at: 11.minutes.ago)
        allow(GlobalMetricsService.send(:statsd)).to receive(:gauge)
      end

      around do |example|
        Timecop.freeze("12:00") { example.run }
      end

      it "records a metric for the number of subscription contents created over
      15 minutes ago (critical)" do
        expect(GlobalMetricsService).to receive(:critical_subscription_contents_total).with(1)
        described_class.new.perform
      end

      it "records a metric for the number of subscription contents created over
      10 minutes ago (warning)" do
        expect(GlobalMetricsService).to receive(:warning_subscription_contents_total).with(2)
        described_class.new.perform
      end

      it "sends the correct values to statsd" do
        expect(GlobalMetricsService.send(:statsd)).to receive(:gauge)
        .with("subscription_contents.critical_total", 1)
        expect(GlobalMetricsService.send(:statsd)).to receive(:gauge)
        .with("subscription_contents.warning_total", 2)

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
      expect(Sidekiq::Queues["cleanup"].size).to eq(1)
    end
  end
end
