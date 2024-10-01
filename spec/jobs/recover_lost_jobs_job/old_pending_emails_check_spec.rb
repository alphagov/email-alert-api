RSpec.describe RecoverLostJobsJob::OldPendingEmailsCheck do
  describe "#call" do
    it "recovers pending emails over an hour old" do
      email = create(:email, created_at: 4.hours.ago)
      expect(SendEmailJob)
        .to receive(:perform_async_in_queue)
        .with(email.id, queue: :send_email_immediate)

      subject.call
    end

    it "does not recover recent pending emails" do
      create(:email, created_at: 2.hours.ago)
      expect(SendEmailJob).to_not receive(:perform_async_in_queue)
      subject.call
    end

    it "does not recover emails that aren't pending" do
      create(:email, created_at: 4.hours.ago, status: :sent)
      expect(ProcessContentChangeJob).not_to receive(:perform_async_in_queue)
      subject.call
    end
  end
end
