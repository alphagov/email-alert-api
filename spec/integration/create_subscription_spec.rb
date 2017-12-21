RSpec.describe "Creating a subscription", type: :request do
  context "with authentication and authorisation" do
    before do
      login_with_internal_app
    end

    context "with a subscribable" do
      let(:subscribable) { create(:subscriber_list) }

      it "returns a 201" do
        params = JSON.dump(address: "test@example.com", subscribable_id: subscribable.id)
        post "/subscriptions", params: params, headers: JSON_HEADERS

        expect(response.status).to eq(201)
      end
    end
  end

  context "without authentication" do
    it "returns a 403" do
      post "/subscriptions", params: {}, headers: {}
      expect(response.status).to eq(403)
    end
  end

  context "without authorisation" do
    it "returns a 403" do
      login_with_signin
      post "/subscriptions", params: {}, headers: {}
      expect(response.status).to eq(403)
    end
  end
end
