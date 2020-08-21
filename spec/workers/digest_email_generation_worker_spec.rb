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

    let(:digest_items) do
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
      allow(DigestItemsQuery).to receive(:call).and_return(digest_items)
    end

    it "delegates creating an email to DigestEmailBuilder" do
      expect(DigestEmailBuilder)
        .to receive(:call)
        .with(address: subscriber.address,
              digest_items: instance_of(Array),
              digest_run: digest_run,
              subscriber_id: subscriber.id)
        .and_call_original

      expect { subject.perform(digest_run_subscriber.id) }
        .to change { Email.count }.by(1)
    end

    it "enqueues delivery" do
      expect(DeliveryRequestWorker).to receive(:perform_async_in_queue)
        .with(instance_of(String), queue: :delivery_digest)

      subject.perform(digest_run_subscriber.id)
    end

    it "records a metric for the delivery attempt" do
      expect(Metrics).to receive(:digest_email_generation)
        .with("daily")

      subject.perform(digest_run_subscriber.id)
    end

    it "marks the DigestRunSubscriber as processed" do
      freeze_time do
        expect { subject.perform(digest_run_subscriber.id) }
          .to change { digest_run_subscriber.reload.processed_at }
          .to(Time.zone.now)
      end
    end

    it "creates SubscriptionContents" do
      expect { subject.perform(digest_run_subscriber.id) }
        .to change(SubscriptionContent, :count)
        .by(2)
    end

    context "when the digest run subscriber has already been processed" do
      before { digest_run_subscriber.update!(processed_at: Time.zone.now) }

      it "doesn't create an email" do
        expect { subject.perform(digest_run_subscriber.id) }
          .to_not change(Email, :count)
      end
    end

    context "when there are no digest items to send" do
      let(:digest_items) { [] }

      it "doesn't create an email" do
        expect { subject.perform(digest_run_subscriber.id) }
          .to_not change(Email, :count)
      end

      it "marks the digest run subscriber as processed" do
        freeze_time do
          expect { subject.perform(digest_run_subscriber.id) }
            .to change { digest_run_subscriber.reload.processed_at }
            .to(Time.zone.now)
        end
      end
    end
  end
end
