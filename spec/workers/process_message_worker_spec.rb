RSpec.describe ProcessMessageWorker do
  let(:message) do
    create(:message,
           criteria_rules: [
             { type: "tag", key: "topics", value: "oil-and-gas/licensing" },
           ])
  end

  let(:email) { create(:email) }

  context "with a subscription" do
    let(:subscriber) { create(:subscriber) }
    let(:subscriber_list) { create(:subscriber_list, tags: { topics: { any: ["oil-and-gas/licensing"] } }) }
    let!(:subscription) { create(:subscription, subscriber: subscriber, subscriber_list: subscriber_list) }

    it "creates subscription content for the message" do
      expect { subject.perform(message.id) }
        .to change { SubscriptionContent.count }
        .by(1)
    end

    it "marks the message as processed" do
      expect { subject.perform(message.id) }
        .to change { message.reload.processed? }
        .to(true)
    end

    it "creates a MatchedMessage" do
      expect { subject.perform(message.id) }
        .to change { MatchedMessage.count }.by(1)
    end

    context "when the subscription content has already been imported for the message" do
      before do
        create(:subscription_content,
               :with_message,
               message: message,
               subscription: subscription)
      end

      it "doesn't create another subscription content" do
        expect { subject.perform(message.id) }
          .to_not(change { SubscriptionContent.count })
      end
    end
  end

  context "with an already processed message" do
    before { message.mark_processed! }

    it "shouldn't process the message" do
      expect(message).to_not receive(:mark_processed!)
      subject.perform(message.id)
    end
  end

  context "with a courtesy subscription" do
    let!(:subscriber) { create(:subscriber, address: Email::COURTESY_EMAIL) }

    it "creates an email for the courtesy email group" do
      expect(MessageEmailBuilder)
        .to receive(:call)
        .with([hash_including(address: subscriber.address)])
        .and_call_original

      subject.perform(message.id)
    end

    it "enqueues the email to send to the courtesy subscription group" do
      expect(DeliveryRequestWorker)
        .to receive(:perform_async_in_queue)
        .with(kind_of(String), queue: :delivery_immediate)

      subject.perform(message.id)
    end
  end
end
