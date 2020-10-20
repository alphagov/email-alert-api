RSpec.describe ImmediateEmailGenerationService do
  describe ".call" do
    let(:content_change) { create(:content_change) }
    let(:subscriber_list) { create(:subscriber_list) }

    before do
      create(:matched_content_change,
             subscriber_list: subscriber_list,
             content_change: content_change)
      allow(SendEmailWorker).to receive(:perform_async_in_queue)
    end

    it "generates emails for active, immediate subscribers" do
      create(:subscription, :ended, subscriber_list: subscriber_list)
      create(:subscription, :daily, subscriber_list: subscriber_list)
      immediate = create(:subscription, :immediately, subscriber_list: subscriber_list)

      expect { described_class.call(content_change) }
        .to change { Email.count }.by(1)
        .and change { SubscriptionContent.where(subscription: immediate).count }
        .by(1)
    end

    it "doesn't generate emails if there are no subscribers" do
      expect { described_class.call(content_change) }
        .not_to(change { Email.count })
    end

    it "queues SendEmailWorkers" do
      create(:subscription, subscriber_list: subscriber_list)

      described_class.call(content_change)

      email_ids = Email.order(created_at: :desc).pluck(:id)
      expect(SendEmailWorker)
        .to have_received(:perform_async_in_queue)
        .with(email_ids.first, an_instance_of(Hash), queue: :send_email_immediate)
    end

    it "sets metrics for the SendEmailWorker" do
      create(:subscription, subscriber_list: subscriber_list)
      metrics = { "content_change_created_at" => content_change.created_at.iso8601 }

      described_class.call(content_change)

      expect(SendEmailWorker)
        .to have_received(:perform_async_in_queue)
        .with(an_instance_of(String), metrics, an_instance_of(Hash))
    end

    context "when a content change is high priority" do
      let(:content_change) { create(:content_change, priority: "high") }

      it "puts the delivery request on the high priority queue" do
        create(:subscription, :immediately, subscriber_list: subscriber_list)

        described_class.call(content_change)
        expect(SendEmailWorker)
          .to have_received(:perform_async_in_queue)
          .with(Email.last.id, an_instance_of(Hash), queue: :send_email_immediate_high)
      end
    end

    context "when given a message" do
      let(:message) { create(:message) }

      before do
        create(:matched_message,
               subscriber_list: subscriber_list,
               message: message)
        create(:subscription, :immediately, subscriber_list: subscriber_list)
      end

      it "can create and queue emails" do
        expect { described_class.call(message) }
          .to change { Email.count }.by(1)
        expect(SendEmailWorker)
          .to have_received(:perform_async_in_queue)
          .with(Email.last.id, an_instance_of(Hash), queue: :send_email_immediate)
      end

      it "doesn't set any metrics" do
        described_class.call(message)
        metrics = {}
        expect(SendEmailWorker)
          .to have_received(:perform_async_in_queue)
          .with(an_instance_of(String), metrics, an_instance_of(Hash))
      end
    end
  end
end
