RSpec.describe RecoverLostJobsWorker do
  describe ".perform" do
    it "recovers unprocessed work over an hour old" do
      work = create(:content_change, created_at: 1.hour.ago, processed_at: nil)
      expect(ProcessContentChangeWorker).to receive(:perform_async).with(work.id)
      subject.perform
    end

    it "does not recover more recent unprocessed work" do
      create(:content_change, created_at: 59.minutes.ago, processed_at: nil)
      expect(ProcessContentChangeWorker).not_to receive(:perform_async)
      subject.perform
    end

    it "does not recover work that is already processed" do
      create(:content_change, created_at: 2.hours.ago, processed_at: 1.hour.ago)
      expect(ProcessContentChangeWorker).not_to receive(:perform_async)
      subject.perform
    end

    it "can also recover Messages" do
      work = create(:message, created_at: 1.hour.ago, processed_at: nil)
      expect(ProcessMessageWorker).to receive(:perform_async).with(work.id)
      subject.perform
    end

    it "can also recover DigestRunSubscribers" do
      work = create(:digest_run_subscriber, created_at: 1.hour.ago, processed_at: nil)
      expect(DigestEmailGenerationWorker).to receive(:perform_async).with(work.id)
      subject.perform
    end

    it "can also recover DigestRuns" do
      saturday = Time.zone.parse("2017-01-07 10:30")
      travel_to saturday

      work1 = create(:digest_run, created_at: 1.hour.ago, date: Date.current, range: :daily)
      work2 = create(:digest_run, created_at: 1.hour.ago, date: Date.current, range: :weekly)

      allow(DailyDigestInitiatorWorker).to receive(:perform_async)
      expect(DailyDigestInitiatorWorker).to receive(:perform_async).with(work1.date.to_s)
      expect(WeeklyDigestInitiatorWorker).to receive(:perform_async).with(work2.date.to_s)

      subject.perform
    end

    it "can create missing work for the week" do
      tuesday = Time.zone.parse("2017-01-10 10:30")
      travel_to tuesday

      subject.perform
      expect(DigestRun.where(range: :daily).where("date > ?", 7.days.ago).count).to eq 7
      expect(DigestRun.where(range: :weekly).where("date > ?", 7.days.ago).count).to eq 1
    end

    it "does not create duplicate work" do
      tuesday = Time.zone.parse("2017-01-10 10:30")
      travel_to tuesday

      create(:digest_run, range: :daily, date: 2.days.ago)
      create(:digest_run, range: :weekly, date: 3.days.ago)

      subject.perform
      expect(DigestRun.where(date: 2.days.ago, range: :daily).count).to eq 1
      expect(DigestRun.where(date: 3.days.ago, range: :weekly).count).to eq 1
    end

    it "does not create work prematurely" do
      early_saturday = Time.zone.parse("2017-01-07 05:30")
      travel_to early_saturday
      subject.perform
      expect(DigestRun.where(date: Date.current).count).to eq 0
    end
  end
end
