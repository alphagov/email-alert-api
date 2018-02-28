RSpec.describe NullifyDeactivatedSubscribersWorker do
  describe ".perform_async" do
    before do
      Sidekiq::Testing.fake! do
        described_class.perform_async
      end
    end

    it "gets added to the cleanup queue" do
      expect(Sidekiq::Queues["cleanup"].size).to eq(1)
    end
  end

  describe ".perform" do
    context "with some subscribers" do
      before do
        create(:subscriber, :nullified)

        create(:subscriber, :deactivated)
        create(:subscriber, :deactivated, deactivated_at: 27.days.ago)
        create(:subscriber, :deactivated, address: "nullify@me.com", deactivated_at: 29.days.ago)

        create(:subscriber, :activated)
      end

      it "nullifies the subscribers that were deactivated more than 28 days ago" do
        expect { subject.perform }
          .to change { Subscriber.not_nullified.count }
          .from(4)
          .to(3)
      end

      it "doesn't deactivate any subscribers" do
        expect { subject.perform }
          .to_not change { Subscriber.activated.count }
          .from(1)
      end

      it "nullifies the right subscriber" do
        expect { subject.perform }
          .to change { Subscriber.find_by(address: "nullify@me.com") }
          .from(anything)
          .to(nil)
      end
    end
  end
end
