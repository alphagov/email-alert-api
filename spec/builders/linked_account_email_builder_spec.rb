RSpec.describe LinkedAccountEmailBuilder do
  describe ".call" do
    let(:subscriber) { build(:subscriber) }

    subject(:email) { described_class.call(subscriber: subscriber) }

    it "lists active subscriptions in the body" do
      active1 = create(:subscription, subscriber: subscriber)
      active2 = create(:subscription, subscriber: subscriber)

      expect(email.body).to include(active1.subscriber_list.title)
      expect(email.body).to include(active2.subscriber_list.title)
    end

    it "does not list ended subscriptions in the body" do
      inactive = create(:subscription, :ended, subscriber: subscriber)

      expect(email.body).not_to include(inactive.subscriber_list.title)
    end
  end
end
