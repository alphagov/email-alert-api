RSpec.describe SubscriptionContentWorker do
  let(:content_change) { create(:content_change, tags: { topics: ["oil-and-gas/licensing"] }) }
  let(:email) { create(:email) }

  before do
    allow(ContentChange).to receive(:find).with(content_change.id).and_return(content_change)
  end

  context "with a subscription" do
    let(:subscriber) { create(:subscriber) }
    let(:subscriber_list) { create(:subscriber_list, tags: { topics: ["oil-and-gas/licensing"] }) }
    let!(:matched_content_change) { create(:matched_content_change, subscriber_list: subscriber_list, content_change: content_change) }
    let!(:subscription) { create(:subscription, subscriber: subscriber, subscriber_list: subscriber_list) }

    context "asynchronously" do
      it "does not raise an error" do
        expect {
          Sidekiq::Testing.fake! do
            SubscriptionContentWorker.perform_async(content_change.id)
            described_class.drain
          end
        }.not_to raise_error
      end
    end

    it "creates subscription content for the content change" do
      expect(SubscriptionContent)
        .to receive(:import!)
        .with(%i(content_change_id subscription_id), [[content_change.id, subscription.id]])

      subject.perform(content_change.id)
    end

    it "marks the content_change as processed" do
      expect(content_change).to receive(:mark_processed!)
      subject.perform(content_change.id)
    end

    context "when the subscription content has already been imported" do
      before { create(:subscription_content, content_change: content_change, subscription: subscription) }

      it "doesn't create another subscription content" do
        expect { subject.perform(content_change.id) }
          .to_not change { SubscriptionContent.count }
          .from(1)
      end
    end
  end

  context "benchmarking" do
    let(:subscriber) { create(:subscriber) }
    let(:content_change) { create(:content_change) }

    before do
      1000.times do
        subscription = create(:subscription, subscriber: subscriber)
        create(:matched_content_change, subscriber_list: subscription.subscriber_list, content_change: content_change)
      end
    end

    it "reports the benchmark" do
      r = Benchmark.measure do
        subject.perform(content_change.id)
      end
      pp r
    end
  end

  context "with more subscriptions than the batch size" do
    let(:subscriber) { create(:subscriber) }
    let(:content_change) { create(:content_change) }

    before do
      2.times do
        subscription = create(:subscription, subscriber: subscriber)
        create(:matched_content_change, subscriber_list: subscription.subscriber_list, content_change: content_change)
      end
    end

    it "calls SubscriptionContent.import! once" do
      expect(SubscriptionContent).to receive(:import!).once

      subject.perform(content_change.id, 1)
    end

    context "when one subscription content has already been imported" do
      before { create(:subscription_content, content_change: content_change, subscription: Subscription.first) }

      it "only creates one additional content change" do
        expect { subject.perform(content_change.id) }
          .to change { SubscriptionContent.count }
          .from(1)
          .to(2)
      end
    end
  end

  context "with a courtesy subscription" do
    let!(:subscriber) do
      create(:subscriber, address: "govuk-email-courtesy-copies@digital.cabinet-office.gov.uk")
    end

    it "creates an email for the courtesy email group" do
      expect(ImmediateEmailBuilder)
        .to receive(:call)
        .with([hash_including(address: subscriber.address)])
        .and_return(double(ids: [0]))
        .and_return(double(ids: ["9a6fa854-9d73-4769-aff7-f340729cf524"]))

      allow(DeliveryRequestWorker)
        .to receive(:perform_async_in_queue)
        .and_return(true)

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
    before do
      content_change.mark_processed!
    end

    it "should return immediate" do
      expect(content_change).to_not receive(:mark_processed!)
      subject.perform(content_change.id)
    end
  end
end
