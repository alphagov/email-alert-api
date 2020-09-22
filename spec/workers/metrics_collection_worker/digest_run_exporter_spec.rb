RSpec.describe MetricsCollectionWorker::DigestRunExporter do
  describe ".call" do
    let(:statsd) { double }

    before do
      create(:digest_run, created_at: 2.days.ago, date: 2.days.ago)
      create(:digest_run, created_at: 21.minutes.ago, date: Time.zone.today)
      allow(GovukStatsd).to receive(:gauge)
    end

    it "records number of unprocessed digest runs over 1 hour old (critical)" do
      expect(GovukStatsd).to receive(:gauge).with("digest_runs.critical_total", 1)
      described_class.call
    end
  end
end
