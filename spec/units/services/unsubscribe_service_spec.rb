RSpec.describe UnsubscribeService do
  describe ".subscriber!" do
    let!(:subscriber) { FactoryBot.create(:subscriber, address: "foo@bar.com") }

    it "nullifies the email address" do
      expect { subject.subscriber!(subscriber) }
        .to change { subscriber.reload.address }
        .from("foo@bar.com")
        .to(nil)
    end

    context "when the subscriber has subscriptions" do
      before do
        FactoryBot.create_list(:subscription, 3, subscriber: subscriber)
      end

      it "removes them" do
        expect { subject.subscriber!(subscriber) }
          .to change(subscriber.subscriptions, :count)
          .from(3)
          .to(0)
      end

      it "does not remove them if the email address update fails" do
        allow_any_instance_of(Subscriber).
          to receive(:valid?).and_raise("failed")

        expect { subject.subscriber!(subscriber) }
          .to raise_error("failed")
          .and change(subscriber.subscriptions, :count)
          .by(0)
      end
    end
  end

  describe ".subscription!" do
    let!(:subscription) { FactoryBot.create(:subscription) }
    let(:subscriber) { subscription.subscriber }

    it "removes the subscription" do
      subject.subscription!(subscription)
      expect(subscription).not_to be_persisted
    end

    it "does not remove the subscription if the email address update fails" do
      allow_any_instance_of(Subscriber).
        to receive(:valid?).and_raise("failed")

      expect { subject.subscriber!(subscriber) }
        .to raise_error("failed")
        .and change(subscriber.subscriptions, :count)
        .by(0)
    end

    context "when it is the only remaining subscription for the subscriber" do
      it "nullifies the email address of the subscriber" do
        expect { subject.subscription!(subscription) }
          .to change { subscriber.reload.address.nil? }
          .from(false)
          .to(true)
      end
    end

    context "when there are other subscriptions for the subscriber" do
      before do
        FactoryBot.create_list(:subscription, 3, subscriber: subscription.subscriber)
      end

      it "does not nullify the email address of the subscriber" do
        subscriber = subscription.subscriber

        subject.subscription!(subscription)
        expect(subscriber.reload.address).not_to be_nil
      end
    end

    context "when there are subscription contents for the subscription" do
      let!(:subscription_content) do
        create(:subscription_content, subscription: subscription)
      end

      it "nullifies the subscription on the subscription_content" do
        expect { subject.subscription!(subscription) }
          .to change { subscription_content.reload.subscription }
          .from(subscription)
          .to(nil)
      end
    end
  end
end
