require "rails_helper"

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

    let(:subscription_content) do
      [
        double(
          subscription_id: subscription_one.id,
          subscriber_list_title: "Test title 1",
          subscriber_list_url: nil,
          subscriber_list_description: nil,
          content: [create(:content_change)],
        ),
        double(
          subscription_id: subscription_two.id,
          subscriber_list_title: "Test title 2",
          subscriber_list_url: "/test-title-2",
          subscriber_list_description: "Test description",
          content: [create(:message)],
        ),
      ]
    end

    before do
      allow(DigestSubscriptionContentQuery)
        .to receive(:call)
        .and_return(subscription_content)
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
        .to(true)
    end

    it "creates SubscriptionContents" do
      expect { subject.perform(digest_run_subscriber.id) }
        .to change(SubscriptionContent, :count)
        .by(2)
    end

    it "doesn't mark the digest run complete" do
      expect { subject.perform(digest_run_subscriber.id) }
        .not_to(change { digest_run.reload.completed? })
    end

    context "when there are no content changes to send" do
      let(:subscription_content) { [] }

      it "doesn't create an email" do
        expect { subject.perform(digest_run_subscriber.id) }
          .to_not change(Email, :count)
      end

      it "marks the digest run subscriber completed" do
        expect { subject.perform(digest_run_subscriber.id) }
          .to change { digest_run_subscriber.reload.completed? }
          .to(true)
      end
    end
  end
end
