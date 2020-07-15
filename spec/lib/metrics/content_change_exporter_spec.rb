RSpec.describe Metrics::ContentChangeExporter do
  describe ".call" do
    let(:statsd) { double }

    before do
      create(:content_change, created_at: 122.minutes.ago)
      create(:content_change, created_at: 99.minutes.ago)
      allow(GovukStatsd).to receive(:gauge)
    end

    it "records number of unprocessed content changes over 10 minutes old (critical)" do
      expect(GovukStatsd).to receive(:gauge).with("content_changes.critical_total", 1)
      described_class.call
    end

    it "records number of unprocessed content changes over 5 minutes old (warning)" do
      expect(GovukStatsd).to receive(:gauge).with("content_changes.warning_total", 2)
      described_class.call
    end
  end
end
