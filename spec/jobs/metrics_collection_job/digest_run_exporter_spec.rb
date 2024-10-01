RSpec.describe MetricsCollectionJob::DigestRunExporter do
  describe ".call" do
    it "records number of unprocessed digest runs over 2 hours old (critical)" do
      # Digest runs must be created after 8am to validate
      travel_to("10:00") do
        create(:digest_run, created_at: 2.days.ago, date: 2.days.ago)
        create(:digest_run, created_at: 21.minutes.ago, date: Time.zone.today)
        expect(GovukStatsd).to receive(:gauge).with("digest_runs.critical_total", 1)
        described_class.call
      end
    end
  end
end
