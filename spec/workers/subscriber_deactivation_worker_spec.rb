RSpec.describe SubscriberDeactivationWorker do
  let(:active_subscriber) { create(:subscriber) }
  let(:inactive_subscriber) { create(:subscriber) }

  before do
    create(:subscription, subscriber: active_subscriber)
    create(:subscription, :ended, subscriber: inactive_subscriber, ended_at: 1.year.ago)
  end

  describe ".perform" do
    context "with an active subscriber" do
      it "does nothing" do
        subject.perform([active_subscriber.id])

        expect(active_subscriber.reload).to be_activated
      end
    end

    context "with an inactive subscriber" do
      it "deactivates the subscriber" do
        subject.perform([inactive_subscriber.id])

        expect(inactive_subscriber.reload).to be_deactivated
      end

      it "uses the ended_at time from the most recent subscription" do
        recent_subscription = create(
          :subscription,
          :ended,
          subscriber: inactive_subscriber,
          ended_at: 1.minute.ago
        )

        subject.perform([inactive_subscriber.id])

        expect(
          inactive_subscriber.reload.deactivated_at
        ).to eq(recent_subscription.reload.ended_at)
      end
    end
  end
end
