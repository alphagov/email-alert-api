RSpec.describe EmailArchiveQuery do
  describe ".call" do
    subject(:scope) { described_class.call }
    let(:now) { Time.zone.now }

    context "when there are archivable emails" do
      before { create(:email, finished_sending_at: now) }

      it "has items" do
        expect(scope.to_a.size).to be_positive
      end
    end

    context "when there are no archivable emails" do
      before { create(:email, archived_at: now) }

      it "doesn't have items" do
        expect(scope.to_a.size).to be_zero
      end
    end

    context "when an email is associated with content changes" do
      let!(:email) { create(:email, finished_sending_at: now) }
      let!(:subscriber) { create(:subscriber) }
      let!(:subscription_contents) do
        [
          create(
            :subscription_content,
            email: email,
            subscription: create(:subscription, subscriber: subscriber),
          ),
          create(
            :subscription_content,
            email: email,
            subscription: create(:subscription, subscriber: subscriber),
          ),
        ]
      end

      it "has subscriber_ids, subscription_ids and content_change_ids" do
        first = scope.first
        subscription_ids = subscription_contents.map(&:subscription_id)
        content_change_ids = subscription_contents.map(&:content_change_id)

        expect(first.subscriber_ids).to match_array(subscriber.id)
        expect(first.subscription_ids).to match_array(subscription_ids)
        expect(first.content_change_ids).to match_array(content_change_ids)
      end
    end

    context "when an email is not associated with content changes" do
      before { create(:email, finished_sending_at: now) }

      it "has empty subscriber_ids, subscription_ids and content_change_ids" do
        first = scope.first
        expect(first.subscriber_ids).to be_empty
        expect(first.subscription_ids).to be_empty
        expect(first.content_change_ids).to be_empty
      end
    end

    context "when an email is associated with digest runs" do
      let!(:email) { create(:email, finished_sending_at: now) }
      let!(:digest_run_subscriber) { create(:digest_run_subscriber) }
      let!(:subscription_contents) do
        [
          create(
            :subscription_content,
            email: email,
            digest_run_subscriber: digest_run_subscriber,
          )
        ]
      end

      it "has digest_run_ids" do
        first = scope.first
        digest_run_ids = [digest_run_subscriber.digest_run_id]
        expect(first.digest_run_ids).to match_array(digest_run_ids)
      end
    end

    context "when an email is not associated with digest runs" do
      before { create(:email, finished_sending_at: now) }

      it "has no digest run ids" do
        expect(scope.first.digest_run_ids).to be_empty
      end
    end

    context "when an email is sent" do
      before do
        create(
          :delivery_attempt,
          status: "delivered",
          email: create(:email, finished_sending_at: now),
        )
      end

      it "is available in the result" do
        expect(scope.first.sent).to be true
      end
    end

    context "when an email is not sent" do
      before do
        create(
          :delivery_attempt,
          status: "technical_failure",
          email: create(:email, finished_sending_at: now),
        )
      end

      it "is available in the result" do
        expect(scope.first.sent).to be false
      end
    end
  end
end
