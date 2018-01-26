RSpec.describe WeeklyDigestInitiatorWorker do
  describe ".perform" do
    it "calls the weekly digest initiator service" do
      expect(WeeklyDigestSchedulerService).to receive(:call)

      subject.perform
    end
  end
end
