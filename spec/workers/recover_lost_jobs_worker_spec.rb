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
  end
end
