RSpec.describe Metrics::SubscriptionContentExporter do
  describe ".call" do
    shared_examples "tests for critical and warning states" do
      context "find subscription contents created within the last hour" do
        let(:statsd) { double }

        before do
          create(:subscription_content, created_at: 51.minutes.ago)
          create(:subscription_content, created_at: 36.minutes.ago)
          allow(GovukStatsd).to receive(:gauge)
        end

        it "records a metric for the number of subscription contents created over
        50 minutes ago (critical)" do
          expect(GovukStatsd).to receive(:gauge).with("subscription_contents.critical_total", 1)
          described_class.call
        end

        it "records a metric for the number of subscription contents created over
        35 minutes ago (warning)" do
          expect(GovukStatsd).to receive(:gauge).with("subscription_contents.warning_total", 2)
          described_class.call
        end
      end
    end

    context "between 09:30 and 11:00" do
      around { |example| travel_to(Time.zone.parse("10:00")) { example.run } }
      include_examples "tests for critical and warning states"
    end

    context "between 12:30 and 13:30" do
      around { |example| travel_to(Time.zone.parse("13:00")) { example.run } }
      include_examples "tests for critical and warning states"
    end

    context "when not scheduled publishing time" do
      let(:statsd) { double }

      before do
        create(:subscription_content, created_at: 21.minutes.ago)
        create(:subscription_content, created_at: 11.minutes.ago)
        allow(GovukStatsd).to receive(:gauge)
      end

      around { |example| travel_to(Time.zone.parse("12:00")) { example.run } }

      it "records a metric for the number of subscription contents created over
      15 minutes ago (critical)" do
        expect(GovukStatsd).to receive(:gauge).with("subscription_contents.critical_total", 1)
        described_class.call
      end

      it "records a metric for the number of subscription contents created over
      10 minutes ago (warning)" do
        expect(GovukStatsd).to receive(:gauge).with("subscription_contents.warning_total", 2)
        described_class.call
      end
    end
  end
end
