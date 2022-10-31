RSpec.describe LinkedAccountEmailBuilder do
  describe ".call" do
    let(:subscriber) { build(:subscriber) }

    subject(:email) { described_class.call(subscriber:) }

    it "lists active subscriptions in the body" do
      active1 = create(:subscription, subscriber:)
      active2 = create(:subscription, subscriber:)

      expect(email.body).to include(active1.subscriber_list.title)
      expect(email.body).to include(active2.subscriber_list.title)
    end

    it "does not list ended subscriptions in the body" do
      inactive = create(:subscription, :ended, subscriber:)

      expect(email.body).not_to include(inactive.subscriber_list.title)
    end
  end
end
