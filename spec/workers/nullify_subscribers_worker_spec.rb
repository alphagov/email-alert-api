RSpec.describe NullifySubscribersWorker do
  describe ".perform" do
    context "when subscribers are older than the nullifyable period" do
      let(:nullifyable_time) { 29.days.ago }

      before do
        @subscriber = create(:subscriber, created_at: nullifyable_time)
      end

      it "nullifies subscribers that don't have any subscriptions" do
        expect { subject.perform }
          .to change { Subscriber.nullified.count }.by(1)
      end

      it "nullifies subscribers that don't have any recent active subscriptions" do
        create(:subscription, :ended, ended_at: nullifyable_time, subscriber: @subscriber)

        expect { subject.perform }
          .to change { Subscriber.nullified.count }.by(1)
      end

      it "doesn't nullify subscribers with recently ended subscriptions" do
        create(:subscription, :ended, subscriber: @subscriber)

        expect { subject.perform }
          .to_not(change { Subscriber.nullified.count })
      end

      it "doesn't nullify subscribers with active subscriptions" do
        create(:subscription, subscriber: @subscriber)

        expect { subject.perform }
          .to_not(change { Subscriber.nullified.count })
      end
    end

    it "doesn't nullify subscribers which have been created recently" do
      create(:subscriber)

      expect { subject.perform }
        .to_not(change { Subscriber.nullified.count })
    end
  end
end
