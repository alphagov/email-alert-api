RSpec.describe "Getting a subscribable", type: :request do
  describe "GET /subscribables/<govuk_delivery_id>" do
    context "the subscribable exists" do
      let!(:subscribable) { create(:subscriber_list, gov_delivery_id: "test135") }

      it "returns it" do
        get "/subscribables/test135"

        subscribable_response = JSON.parse(response.body).deep_symbolize_keys[:subscribable]

        expect(subscribable_response[:id]).to eq(subscribable.id)
      end
    end

    context "the subscribable doesn't exist" do
      it "returns a 404" do
        get "/subscribables/test135"

        expect(response.status).to eq(404)
      end
    end
  end
end
