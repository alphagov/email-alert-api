RSpec.describe "Subscriptions", type: :request do
  context "with authentication and authorisation" do
    before do
      login_with_internal_app
    end

    context "when listing subscriptions for a subscriber" do
      context "with an existing subscriber" do
        let!(:subscriber) { create(:subscriber) }
        let!(:subscriber_list_1) { create(:subscriber_list) }
        let!(:subscriber_list_2) { create(:subscriber_list) }
        let!(:subscriber_list_3) { create(:subscriber_list) }
        let!(:subscription_1) { create(:subscription, subscriber: subscriber, subscriber_list: subscriber_list_1) }
        let!(:subscription_2) { create(:subscription, subscriber: subscriber, subscriber_list: subscriber_list_2, ended_at: Time.now, ended_reason: :frequency_changed) }
        let!(:subscription_3) { create(:subscription, subscriber: subscriber, subscriber_list: subscriber_list_3, frequency: :daily) }

        it "lists all active subscriptions" do
          get "/subscribers/#{subscriber.id}/subscriptions"
          expect(data[:subscriptions].length).to eq(2)
        end

        it "does not list any ended subscriptions" do
          get "/subscribers/#{subscriber.id}/subscriptions"
          ended_subscription = data[:subscriptions].detect { |s| s[:id] == subscription_2.id }
          expect(ended_subscription).to be_nil
        end
      end

      context "without an existing subscriber" do
        it "returns status code 404" do
          get "/subscribers/x12345/subscriptions"
          expect(response.status).to eq(404)
        end
      end
    end

    context "when changing a subscriber's email address" do
      context "with an existing subscriber" do
        let!(:subscriber) { create(:subscriber) }

        it "changes the email address if the new email address is valid" do
          patch "/subscribers/#{subscriber.id}", params: { new_address: "new-test@example.com" }
          expect(response.status).to eq(200)
          expect(data[:subscriber][:address]).to eq("new-test@example.com")
        end

        it "returns an error message if the new email address is invalid" do
          patch "/subscribers/#{subscriber.id}", params: { new_address: "invalid" }
          expect(response.status).to eq(422)
        end
      end

      context "without an existing subscriber" do
        it "returns a 404" do
          patch "/subscribers/x12345", params: { new_address: "new-doesnotexist@example.com" }
          expect(response.status).to eq(404)
        end
      end
    end
  end

  context "without authentication" do
    it "returns a 403" do
      get "/subscribers/1/subscriptions"
      expect(response.status).to eq(403)
    end
  end

  context "without authorisation" do
    it "returns a 403" do
      login_with_signin
      get "/subscribers/1/subscriptions"
      expect(response.status).to eq(403)
    end
  end
end
