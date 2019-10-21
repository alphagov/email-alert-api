RSpec.describe ImmediateContentChangeEmailGenerationWorker do
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
        content_change = create(:content_change)

        create(
          :subscription_content,
          subscription: subscription_one,
          content_change: content_change,
        )

        create(
          :subscription_content,
          subscription: subscription_two,
          content_change: content_change,
        )

        described_class.new.perform(content_change.id)

        expect(Email.count).to eq(1)
      end
    end

    context "with many subscription contents" do
      let!(:content_change) { create(:content_change) }

      before do
        50.times do
          create(:subscription_content, content_change: content_change)
        end
      end

      it "should match up with the right emails" do
        perform_with_fake_sidekiq(content_change.id)

        SubscriptionContent.includes(:email, subscription: :subscriber).find_each do |subscription_content|
          expect(subscription_content.email.address)
            .to eq(subscription_content.subscription.subscriber.address)
        end
      end
    end

    context "with a subscription content" do
      let!(:subscription_content) { create(:subscription_content) }

      before do
        create(:subscription_content, email: create(:email))
        create(:subscription_content, subscription: create(:subscription, subscriber: create(:subscriber, :nullified)))
      end

      it "should create an email" do
        expect { perform_with_fake_sidekiq(subscription_content.content_change_id) }
          .to change { Email.count }
          .by(1)
      end

      it "should associate the subscription content with the email" do
        perform_with_fake_sidekiq(subscription_content.content_change_id)
        expect(subscription_content.reload.email).to_not be_nil
      end

      it "should queue a delivery email job" do
        perform_with_fake_sidekiq(subscription_content.content_change_id)
        expect(DeliveryRequestWorker.jobs.size).to eq(1)
      end

      context "with a high priority content change" do
        before do
          subscription_content.content_change.update(priority: "high")
        end

        it "should queue a delivery email job with a high priority" do
          expect(DeliveryRequestWorker).to receive(:perform_async_in_queue)
            .with(an_instance_of(String), queue: :delivery_immediate_high)

          perform_with_fake_sidekiq(subscription_content.content_change_id)
        end
      end
    end

    context "with multiple content changes" do
      it "will only process subscription contents for the content change it is passed" do
        subscriber_one = create(:subscriber)
        subscriber_two = create(:subscriber)
        subscription_one = create(:subscription, subscriber: subscriber_one)
        subscription_two = create(:subscription, subscriber: subscriber_two)
        content_change_one = create(:content_change)
        content_change_two = create(:content_change)

        subscription_content_one = create(
          :subscription_content,
          subscription: subscription_one,
          content_change: content_change_one,
            )

        subscription_content_two = create(
          :subscription_content,
          subscription: subscription_two,
          content_change: content_change_two,
            )

        described_class.new.perform(content_change_one.id)

        expect(Email.count).to eq(1)
        subscription_content_one.reload
        subscription_content_two.reload
        expect(subscription_content_one.email.address).to eq(subscriber_one.address)
        expect(subscription_content_two.email).to be_nil
      end
    end
  end
end
