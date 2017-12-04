require "rails_helper"

RSpec.describe SubscribablesController, type: :request do
  describe "GET /subscribables/<govuk_delivery_id>" do
    it "returns the subscribable" do
      subscribable = create(:subscriber_list, gov_delivery_id: "test135")
      get "/subscribables/test135"

      subscribable_response = JSON.parse(response.body).deep_symbolize_keys[:subscribable]

      expect(subscribable_response[:id]).to eq(subscribable.id)
    end
  end
end
