RSpec.describe RecoverLostJobsWorker do
  describe ".perform" do
    describe "ContentChange recovery" do
      it "does not requeue incomplete content changes that are under 1-hour old" do
        create(:content_change, created_at: 59.minutes.ago)
        expect(ProcessContentChangeWorker).not_to receive(:perform_async)
        subject.perform
      end

      it "requeues incomplete content changes that are over 1-hour old" do
        create(:content_change, created_at: 1.hour.ago)
        expect(ProcessContentChangeWorker).to receive(:perform_async)
        subject.perform
      end
    end

    describe "Message recovery" do
      it "does not requeue incomplete messages that are under 1-hour old" do
        create(:message, created_at: 59.minutes.ago)
        expect(ProcessMessageWorker).not_to receive(:perform_async)
        subject.perform
      end

      it "requeues incomplete messages that are over 1-hour old" do
        create(:message, created_at: 1.hour.ago)
        expect(ProcessMessageWorker).to receive(:perform_async)
        subject.perform
      end
    end

    describe "DigestRunSubscriber recovery" do
      it "does not requeue unprocessed work that is under 1-hour old" do
        create(:digest_run_subscriber, created_at: 59.minutes.ago)
        expect(DigestEmailGenerationWorker).not_to receive(:perform_async)
        subject.perform
      end

      it "requeues incomplete work that is over 1-hour old" do
        create(:digest_run_subscriber, created_at: 1.hour.ago)
        expect(DigestEmailGenerationWorker).to receive(:perform_async)
        subject.perform
      end
    end

    describe "DigestRun recovery" do
      before do
        saturday = Time.zone.parse("2017-01-07 10:30")
        travel_to saturday
      end

      it "does not requeue unprocessed work that is under 1-hour old" do
        create(:digest_run, created_at: 59.minutes.ago, date: Date.current, range: :daily)
        create(:digest_run, created_at: 59.minutes.ago, date: Date.current, range: :weekly)
        expect(DailyDigestInitiatorWorker).not_to receive(:perform_async)
        expect(WeeklyDigestInitiatorWorker).not_to receive(:perform_async)
        subject.perform
      end

      it "requeues incomplete work that is over 1-hour old" do
        create(:digest_run, created_at: 1.hour.ago, date: Date.current, range: :daily)
        create(:digest_run, created_at: 1.hour.ago, date: Date.current, range: :weekly)
        expect(DailyDigestInitiatorWorker).to receive(:perform_async)
        expect(WeeklyDigestInitiatorWorker).to receive(:perform_async)
        subject.perform
      end
    end
  end
end
