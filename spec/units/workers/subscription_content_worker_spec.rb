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

    context "when we error" do
      it "reports errors when creating a SubscriptionContent in the database to Sentry and swallows them" do
        allow(SubscriptionContent)
          .to receive(:import!)
          .and_raise(ActiveRecord::RecordInvalid)

        expect(Raven)
          .to receive(:capture_exception)
          .with(
            instance_of(ActiveRecord::RecordInvalid),
            tags: { version: 2 }
          )

        expect {
          subject.perform(content_change.id)
        }.not_to raise_error
      end
    end

    it "creates subscription content for the content change" do
      expect(SubscriptionContent)
        .to receive(:import!)
        .with([{ content_change_id: content_change.id, subscription_id: subscription.id }])

      subject.perform(content_change.id)
    end

    it "marks the content_change as processed" do
      expect(content_change).to receive(:mark_processed!)
      subject.perform(content_change.id)
    end
  end

  context "with a courtesy subscription" do
    let!(:subscriber) do
      create(:subscriber, address: "govuk-email-courtesy-copies@digital.cabinet-office.gov.uk")
    end

    it "creates an email for the courtesy email group" do
      expect(ImmediateEmailBuilder)
        .to receive(:call)
        .with([hash_including(subscriber: subscriber)])
        .and_return(double(ids: [0]))

      subject.perform(content_change.id)
    end

    it "enqueues the email to send to the courtesy subscription group" do
      expect(DeliveryRequestWorker)
        .to receive(:perform_async_for_immediate)
        .with(kind_of(Integer), priority: :normal)

      subject.perform(content_change.id)
    end
  end
end
