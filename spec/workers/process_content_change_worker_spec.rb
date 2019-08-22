RSpec.describe ProcessContentChangeWorker do
  let(:content_change) { create(:content_change, tags: { topics: { any: ["oil-and-gas/licensing"] } }) }
  let(:email) { create(:email) }

  context "with a subscription" do
    let(:subscriber) { create(:subscriber) }
    let(:subscriber_list) { create(:subscriber_list, tags: { topics: { any: ["oil-and-gas/licensing"] } }) }
    let!(:matched_content_change) { create(:matched_content_change, subscriber_list: subscriber_list, content_change: content_change) }
    let!(:subscription) { create(:subscription, subscriber: subscriber, subscriber_list: subscriber_list) }

    it "creates subscription content for the content change" do
      expect { subject.perform(content_change.id) }
        .to change { SubscriptionContent.count }
        .by(1)
    end

    it "marks the content_change as processed" do
      expect { subject.perform(content_change.id) }
        .to change { content_change.reload.processed? }
        .to(true)
    end

    context "when the subscription content has already been imported" do
      before { create(:subscription_content, content_change: content_change, subscription: subscription) }

      it "doesn't create another subscription content" do
        expect { subject.perform(content_change.id) }
          .to_not(change { SubscriptionContent.count })
      end
    end
  end

  context "with a courtesy subscription" do
    let!(:subscriber) { create(:subscriber, address: Email::COURTESY_EMAIL) }

    it "creates an email for the courtesy email group" do
      expect(ContentChangeEmailBuilder)
        .to receive(:call)
        .with([hash_including(address: subscriber.address)])
        .and_call_original

      subject.perform(content_change.id)
    end

    it "enqueues the email to send to the courtesy subscription group" do
      expect(DeliveryRequestWorker)
        .to receive(:perform_async_in_queue)
        .with(kind_of(String), queue: :delivery_immediate)

      subject.perform(content_change.id)
    end
  end

  context "with an already processed content change" do
    before { content_change.mark_processed! }

    it "should return immediate" do
      expect(content_change).to_not receive(:mark_processed!)
      subject.perform(content_change.id)
    end
  end
end
