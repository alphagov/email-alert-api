RSpec.describe Metrics::MessageExporter do
  describe ".call" do
    let(:statsd) { double }

    before do
      3.times { create(:message, processed_at: nil, created_at: 10.minutes.ago) }
      2.times { create(:message, processed_at: nil, created_at: 5.minutes.ago) }
      allow(GovukStatsd).to receive(:gauge)
    end

    it "records a metric for the total number of unprocessed messages created
    over 10 minutes ago (critical)" do
      expect(GovukStatsd).to receive(:gauge).with("messages.critical_total", 3)
      described_class.call
    end

    it "records a metric for the total number of unprocessed messages created
    over 5 minutes ago (warning)" do
      expect(GovukStatsd).to receive(:gauge).with("messages.warning_total", 5)
      described_class.call
    end
  end
end
