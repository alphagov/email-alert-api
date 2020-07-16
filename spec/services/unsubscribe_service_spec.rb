RSpec.describe UnsubscribeService do
  describe ".subscriber!" do
    let!(:subscriber) { create(:subscriber, address: "foo@bar.com") }

    it "deactivates the subscriber" do
      expect { subject.subscriber!(subscriber, :unsubscribed) }
        .to change { subscriber.reload.deactivated? }
        .from(false)
        .to(true)
    end

    context "when the subscriber has subscriptions" do
      before do
        create_list(:subscription, 3, subscriber: subscriber)
      end

      it "removes them" do
        expect { subject.subscriber!(subscriber, :unsubscribed) }
          .to change(subscriber.active_subscriptions, :count)
          .from(3)
          .to(0)
      end

      it "does not remove them if the email address update fails" do
        allow_any_instance_of(Subscriber)
          .to receive(:valid?).and_raise("failed")

        expect { subject.subscriber!(subscriber, :unsubscribed) }
          .to raise_error("failed")
          .and change(subscriber.active_subscriptions, :count)
          .by(0)
      end
    end
  end

  describe ".subscription!" do
    let!(:subscription) { create(:subscription) }
    let(:subscriber) { subscription.subscriber }

    it "removes the subscription" do
      subject.subscription!(subscription, :unsubscribed)
      expect(Subscription.active.find_by(id: subscription.id)).to be_nil
    end

    it "does not remove the subscription if the email address update fails" do
      allow_any_instance_of(Subscriber)
        .to receive(:valid?).and_raise("failed")

      expect { subject.subscriber!(subscriber, :unsubscribed) }
        .to raise_error("failed")
        .and change(subscriber.active_subscriptions, :count)
        .by(0)
    end

    context "when it is the only remaining subscription for the subscriber" do
      it "deactivates the subscriber" do
        expect { subject.subscription!(subscription, :unsubscribed) }
          .to change { subscriber.reload.deactivated? }
          .from(false)
          .to(true)
      end
    end

    context "when there are other subscriptions for the subscriber" do
      before do
        create_list(:subscription, 3, subscriber: subscription.subscriber)
      end

      it "does not nullify the email address of the subscriber" do
        subscriber = subscription.subscriber

        subject.subscription!(subscription, :unsubscribed)
        expect(subscriber.reload.address).not_to be_nil
      end
    end
  end
end
