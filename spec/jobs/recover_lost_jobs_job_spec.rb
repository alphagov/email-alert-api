RSpec.describe RecoverLostJobsJob do
  describe "#perform" do
    it "delegates recovery" do
      expect_any_instance_of(RecoverLostJobsJob::UnprocessedCheck).to receive(:call)
      expect_any_instance_of(RecoverLostJobsJob::MissingDigestRunsCheck).to receive(:call)
      expect_any_instance_of(RecoverLostJobsJob::OldPendingEmailsCheck).to receive(:call)

      subject.perform
    end
  end
end
