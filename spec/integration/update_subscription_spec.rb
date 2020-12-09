RSpec.describe "Updating a subscription", type: :request do
  let!(:subscription) { create(:subscription, frequency: "immediately") }

  context "with authentication and authorisation" do
    before do
      login_with_internal_app
    end

    context "with an existing subscription" do
      it "changes the frequency if the new frequency is valid" do
        patch "/subscriptions/#{subscription.id}", params: { frequency: "weekly" }
        expect(response.status).to eq(200)
        expect(data[:subscription][:frequency]).to eq("weekly")
      end

      it "returns an error message if the new frequency is invalid" do
        patch "/subscriptions/#{subscription.id}", params: { frequency: "monthly" }
        expect(response.status).to eq(422)
      end

      it "returns the current subscription if the frequency is not changed" do
        patch "/subscriptions/#{subscription.id}", params: { frequency: "immediately" }
        expect(response.status).to eq(200)
        expect(data[:subscription][:id]).to eq(subscription.id)
      end
    end

    context "without an existing subscription" do
      it "returns a 404" do
        patch "/subscriptions/xxxx", params: { frequency: "daily" }
        expect(response.status).to eq(404)
      end
    end
  end

  context "without authentication" do
    it "returns a 401" do
      without_login do
        patch "/subscriptions/#{subscription.id}", params: { frequency: "immediately" }
        expect(response.status).to eq(401)
      end
    end
  end

  context "without authorisation" do
    it "returns a 403" do
      login_with_signin
      patch "/subscriptions/#{subscription.id}", params: { frequency: "immediately" }
      expect(response.status).to eq(403)
    end
  end
end
