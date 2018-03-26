require 'rails_helper'

RSpec.describe DigestEmailGenerationWorker do
  describe ".perform_async" do
    before do
      Sidekiq::Testing.fake! do
        described_class.perform_async
      end
    end

    it "gets put on the email_generation_digest queue" do
      expect(Sidekiq::Queues["email_generation_digest"].size).to eq(1)
    end
  end

  describe ".perform" do
    let(:subscriber) { create(:subscriber) }

    let(:subscription_one) do
      create(:subscription, subscriber: subscriber)
    end

    let(:subscription_two) do
      create(:subscription, subscriber: subscriber)
    end

    let(:digest_run) { create(:digest_run) }

    let(:digest_run_subscriber) do
      create(:digest_run_subscriber, digest_run: digest_run, subscriber: subscriber)
    end

    let(:subscription_content_change_query_results) do
      [
        double(
          subscription_id: subscription_one.id,
          subscriber_list_title: "Test title 1",
          content_changes: [create(:content_change)],
        ),
        double(
          subscription_id: subscription_two.id,
          subscriber_list_title: "Test title 2",
          content_changes: [create(:content_change)],
        ),
      ]
    end

    before do
      allow(SubscriptionContentChangeQuery).to receive(:call).and_return(
        subscription_content_change_query_results
      )
    end

    it "accepts digest_run_subscriber_id" do
      expect {
        subject.perform(digest_run_subscriber.id)
      }.not_to raise_error
    end

    it "creates an email" do
      expect { subject.perform(digest_run_subscriber.id) }
        .to change { Email.count }.by(1)
    end

    it "enqueues delivery" do
      expect(DeliveryRequestWorker).to receive(:perform_async_in_queue)
        .with(instance_of(String), queue: :delivery_digest)

      subject.perform(digest_run_subscriber.id)
    end

    it "records a metric for the delivery attempt" do
      expect(MetricsService).to receive(:digest_email_generation)
        .with("daily")

      subject.perform(digest_run_subscriber.id)
    end

    it "marks the DigestRunSubscriber completed" do
      expect { subject.perform(digest_run_subscriber.id) }
        .to change { digest_run_subscriber.reload.completed? }
        .from(false)
        .to(true)
    end

    it "creates SubscriptionContents" do
      expect { subject.perform(digest_run_subscriber.id) }
        .to change(SubscriptionContent, :count)
        .by(subscription_content_change_query_results.count)
    end

    it "marks the digest run complete" do
      expect { subject.perform(digest_run_subscriber.id) }
        .to change { digest_run.reload.completed? }
        .from(false)
        .to(true)
    end

    context "when there are incomplete DigestRunSubscribers left" do
      before do
        # Create an extra instance of digest run subscriber so more are left
        create(:digest_run_subscriber, digest_run: digest_run)
      end

      it "doesn't mark the digest run complete" do
        expect { subject.perform(digest_run_subscriber.id) }
          .not_to(change { digest_run.reload.completed? })
      end
    end
  end
end
