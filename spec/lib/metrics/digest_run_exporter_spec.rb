RSpec.describe Metrics::DigestRunExporter do
  describe ".call" do
    let(:statsd) { double }

    before do
      create(:digest_run, created_at: 61.minutes.ago)
      create(:digest_run, created_at: 21.minutes.ago)
      allow(GovukStatsd).to receive(:gauge)
    end

    it "records number of unprocessed digest runs over 1 hour old (critical)" do
      expect(GovukStatsd).to receive(:gauge).with("digest_runs.critical_total", 1)
      described_class.call
    end

    it "records number of unprocessed digest runs over 20 minutes old (warning)" do
      expect(GovukStatsd).to receive(:gauge).with("digest_runs.warning_total", 2)
      described_class.call
    end
  end
end
