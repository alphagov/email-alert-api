RSpec.describe ImmediateMessageEmailGenerationWorker do
  describe ".perform" do
    def perform_with_fake_sidekiq(content_change_id)
      Sidekiq::Testing.fake! do
        DeliveryRequestWorker.jobs.clear
        described_class.new.perform(content_change_id)
      end
    end

    context "with subscribers that have duplicate subscription contents" do
      it "deduplicates when creating the emails" do
        subscriber_one = create(:subscriber)
        subscription_one = create(:subscription, subscriber: subscriber_one)
        subscription_two = create(:subscription, subscriber: subscriber_one)
        message = create(:message)

        create(
          :subscription_content,
          subscription: subscription_one,
          message: message,
          content_change: nil,
        )

        create(
          :subscription_content,
          subscription: subscription_two,
          message: message,
          content_change: nil,
        )

        described_class.new.perform(message.id)

        expect(Email.count).to eq(1)
      end
    end

    context "with many subscription contents" do
      let!(:message) { create(:message) }

      before do
        50.times do
          create(:subscription_content, message: message, content_change: nil)
        end
      end

      it "should match up with the right emails" do
        perform_with_fake_sidekiq(message.id)

        SubscriptionContent.includes(:email, subscription: :subscriber).find_each do |subscription_content|
          expect(subscription_content.email.address)
            .to eq(subscription_content.subscription.subscriber.address)
        end
      end
    end

    context "with a subscription content" do
      let!(:subscription_content) { create(:subscription_content, message: create(:message), content_change: nil) }

      before do
        create(:subscription_content, email: create(:email))
        create(:subscription_content, subscription: create(:subscription, subscriber: create(:subscriber, :nullified)))
      end

      it "should create an email" do
        expect { perform_with_fake_sidekiq(subscription_content.message_id) }
          .to change { Email.count }
          .by(1)
      end

      it "should associate the subscription content with the email" do
        perform_with_fake_sidekiq(subscription_content.message_id)
        expect(subscription_content.reload.email).to_not be_nil
      end

      it "should queue a delivery email job" do
        perform_with_fake_sidekiq(subscription_content.message_id)
        expect(DeliveryRequestWorker.jobs.size).to eq(1)
      end

      context "with a high priority message" do
        before do
          subscription_content.message.update(priority: "high")
        end

        it "should queue a delivery email job with a high priority" do
          expect(DeliveryRequestWorker).to receive(:perform_async_in_queue)
            .with(an_instance_of(String), queue: :delivery_immediate_high)

          perform_with_fake_sidekiq(subscription_content.message_id)
        end
      end
    end

    context "with multiple messages" do
      it "will only process subscription contents for the message it is passed" do
        subscriber_one = create(:subscriber)
        subscriber_two = create(:subscriber)
        subscription_one = create(:subscription, subscriber: subscriber_one)
        subscription_two = create(:subscription, subscriber: subscriber_two)
        message_one = create(:message)
        message_two = create(:message)

        subscription_content_one = create(
          :subscription_content,
          subscription: subscription_one,
          message: message_one,
          content_change: nil,
            )

        subscription_content_two = create(
          :subscription_content,
          subscription: subscription_two,
          message: message_two,
          content_change: nil,
            )

        described_class.new.perform(message_one.id)

        expect(Email.count).to eq(1)
        subscription_content_one.reload
        subscription_content_two.reload
        expect(subscription_content_one.email.address).to eq(subscriber_one.address)
        expect(subscription_content_two.email).to be_nil
      end
    end
  end
end
