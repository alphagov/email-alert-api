RSpec.describe UpdateLastAlertedAtSubscriberListService do
  describe ".call" do
    let(:associated_subscription) { create(:subscription) }
    let(:associated_content_change) { create(:content_change) }

    it "updates the last_alerted_at date for the associated_subscription subscriber_list" do
      create(
        :matched_content_change,
        subscriber_list: associated_subscription.subscriber_list,
        content_change: associated_content_change,
      )

      expect {
        described_class.call(associated_content_change)
      }.to change { associated_subscription.subscriber_list.reload.last_alerted_at }.from(nil).to(be_present)
    end
  end
end
