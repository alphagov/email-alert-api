RSpec.describe RecoverLostJobsWorker::UnprocessedCheck do
  describe "#call" do
    it "recovers unprocessed work over an hour old" do
      work = create(:content_change, created_at: 1.hour.ago, processed_at: nil)
      expect(ProcessContentChangeWorker).to receive(:perform_async).with(work.id)
      subject.call
    end

    it "does not recover more recent unprocessed work" do
      create(:content_change, created_at: 59.minutes.ago, processed_at: nil)
      expect(ProcessContentChangeWorker).not_to receive(:perform_async)
      subject.call
    end

    it "does not recover work that is already processed" do
      create(:content_change, created_at: 2.hours.ago, processed_at: 1.hour.ago)
      expect(ProcessContentChangeWorker).not_to receive(:perform_async)
      subject.call
    end

    it "can also recover Messages" do
      work = create(:message, created_at: 1.hour.ago, processed_at: nil)
      expect(ProcessMessageWorker).to receive(:perform_async).with(work.id)
      subject.call
    end

    it "can also recover DigestRunSubscribers" do
      work = create(:digest_run_subscriber, created_at: 1.hour.ago, processed_at: nil)
      expect(DigestEmailGenerationWorker).to receive(:perform_async).with(work.id)
      subject.call
    end

    it "can also recover DigestRuns" do
      saturday = Time.zone.parse("2017-01-07 10:30")
      travel_to saturday

      work1 = create(:digest_run, created_at: 1.hour.ago, date: Date.current, range: :daily)
      work2 = create(:digest_run, created_at: 1.hour.ago, date: Date.current, range: :weekly)

      expect(DailyDigestInitiatorJob).to receive(:perform_async).with(work1.date.to_s)
      expect(WeeklyDigestInitiatorWorker).to receive(:perform_async).with(work2.date.to_s)

      subject.call
    end
  end
end
