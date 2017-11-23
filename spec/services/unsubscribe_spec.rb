require "rails_helper"

RSpec.describe Unsubscribe do
  describe ".subscriber!" do
    let!(:subscriber) { FactoryGirl.create(:subscriber, address: "foo@bar.com") }

    it "nullifies the email address" do
      expect { subject.subscriber!(subscriber) }
        .to change { subscriber.reload.address }
        .from("foo@bar.com")
        .to(nil)
    end

    it "removes the subscriber's subscriptions" do
      FactoryGirl.create_list(:subscription, 3, subscriber: subscriber)

      expect { subject.subscriber!(subscriber) }
        .to change { subscriber.subscriptions.count }
        .from(3)
        .to(0)
    end
  end

  describe ".subscription!" do
    let!(:subscription) { FactoryGirl.create(:subscription) }

    it "removes the subscription" do
      subject.subscription!(subscription)
      expect(subscription).not_to be_persisted
    end

    context "when it is the only remaining subscription for the subscriber" do
      it "nullifies the email address of the subscriber" do
        subscriber = subscription.subscriber

        expect { subject.subscription!(subscription) }
          .to change { subscriber.reload.address.nil? }
          .from(false)
          .to(true)
      end
    end

    context "when there are other subscriptions for the subscriber" do
      before do
        FactoryGirl.create_list(:subscription, 3, subscriber: subscription.subscriber)
      end

      it "does not nullify the email address of the subscriber" do
        subscriber = subscription.subscriber

        subject.subscription!(subscription)
        expect(subscriber.reload.address).not_to be_nil
      end
    end
  end
end
