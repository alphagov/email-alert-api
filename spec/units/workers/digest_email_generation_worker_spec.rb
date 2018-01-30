require 'rails_helper'

RSpec.describe DigestEmailGenerationWorker do
  let(:subscriber) { create(:subscriber, id: 1) }
  let!(:subscription_one) {
    create(:subscription, id: 1, subscriber_id: subscriber.id)
  }
  let!(:subscription_two) {
    create(:subscription, id: 2, subscriber_id: subscriber.id)
  }
  let!(:digest_run) { create(:digest_run, id: 10) }

  let(:subscription_content_change_query_results) {
    [
      double(
        subscription_id: 1,
        subscription_uuid: "ABC1",
        subscriber_list_title: "Test title 1",
        content_changes: [
          create(:content_change, public_updated_at: "1/1/2016 10:00"),
        ],
      ),
      double(
        subscription_id: 2,
        subscription_uuid: "ABC2",
        subscriber_list_title: "Test title 2",
        content_changes: [
          create(:content_change, public_updated_at: "4/1/2016 10:00"),
        ],
      ),
    ]
  }

  before do
    allow(SubscriptionContentChangeQuery).to receive(:call).and_return(
      subscription_content_change_query_results
    )
  end

  it "accepts a subscriber_id and a digest_run_id" do
    expect {
      subject.perform(subscriber_id: 1, digest_run_id: 10)
    }.not_to raise_error
  end

  it "creates an email" do
    expect { subject.perform(subscriber_id: 1, digest_run_id: 10) }
      .to change { Email.count }.by(1)
  end

  it "enqueues delivery" do
    expect(DeliveryRequestWorker).to receive(:perform_async_in_queue)
      .with(instance_of(Integer), queue: :delivery_digest)

    subject.perform(subscriber_id: 1, digest_run_id: 10)
  end
end
