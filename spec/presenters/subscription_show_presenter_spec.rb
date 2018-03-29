RSpec.describe SubscriptionShowPresenter do
  describe ".call" do
    let(:expected_fields) do
      %i[
        id
        frequency
        source
        ended
        ended_at
        ended_reason
        created_at
        updated_at
        subscriber_list
        subscriber
      ]
    end
    let(:subscription) { create(:subscription) }

    it "has expected fields" do
      response = described_class.call(subscription)
      expect(response.keys).to match(expected_fields)
    end
  end
end
