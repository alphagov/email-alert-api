RSpec.describe BulkEmailSenderService do
  let(:email_subject) { "email subject" }
  let(:body) { "body" }
  let(:subscriber_lists) { [create(:subscription).subscriber_list] }

  describe ".call" do
    it "adds a delivery request to the queue" do
      expect(DeliveryRequestWorker).to receive(:perform_async).with(
        kind_of(String), :delivery_immediate
      ).and_call_original

      Sidekiq::Testing.fake! do
        described_class.call(subject: email_subject, body: body, subscriber_lists: subscriber_lists)
      end

      expect(DeliveryRequestWorker.jobs.size).to eq(1)
    end
  end
end
