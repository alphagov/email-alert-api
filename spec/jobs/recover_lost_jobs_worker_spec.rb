RSpec.describe RecoverLostJobsWorker do
  describe "#perform" do
    it "delegates recovery" do
      expect_any_instance_of(RecoverLostJobsWorker::UnprocessedCheck).to receive(:call)
      expect_any_instance_of(RecoverLostJobsWorker::MissingDigestRunsCheck).to receive(:call)
      expect_any_instance_of(RecoverLostJobsWorker::OldPendingEmailsCheck).to receive(:call)

      subject.perform
    end
  end
end
