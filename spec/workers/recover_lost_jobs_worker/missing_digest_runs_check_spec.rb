RSpec.describe RecoverLostJobsWorker::MissingDigestRunsCheck do
  describe "#call" do
    it "can create missing work for the week" do
      tuesday = Time.zone.parse("2017-01-10 10:30")
      travel_to tuesday

      subject.call
      expect(DigestRun.where(range: :daily).where("date > ?", 7.days.ago).count).to eq 7
      expect(DigestRun.where(range: :weekly).where("date > ?", 7.days.ago).count).to eq 1
    end

    it "does not create duplicate work" do
      tuesday = Time.zone.parse("2017-01-10 10:30")
      travel_to tuesday

      create(:digest_run, range: :daily, date: 2.days.ago)
      create(:digest_run, range: :weekly, date: 3.days.ago)

      subject.call
      expect(DigestRun.where(date: 2.days.ago, range: :daily).count).to eq 1
      expect(DigestRun.where(date: 3.days.ago, range: :weekly).count).to eq 1
    end

    it "does not create work prematurely" do
      early_saturday = Time.zone.parse("2017-01-07 05:30")
      travel_to early_saturday
      subject.call
      expect(DigestRun.where(date: Date.current).count).to eq 0
    end
  end
end
