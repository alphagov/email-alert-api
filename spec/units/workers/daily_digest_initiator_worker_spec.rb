RSpec.describe DailyDigestInitiatorWorker do
  describe ".perform" do
    it "calls the daily digest initiator service" do
      expect(DailyDigestSchedulerService).to receive(:call)

      subject.perform
    end
  end
end
