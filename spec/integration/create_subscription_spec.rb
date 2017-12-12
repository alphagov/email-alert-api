RSpec.describe "Creating a subscription", type: :request do
  context "with a subscribable" do
    let(:subscribable) { create(:subscriber_list) }

    it "returns a 201" do
      params = JSON.dump(address: "test@example.com", subscribable_id: subscribable.id)
      post "/subscriptions", params: params, headers: JSON_HEADERS

      expect(response.status).to eq(201)
    end
  end
end
