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
          get "/subscribers/#{subscriber.address}/subscriptions"
          expect(data[:subscriptions].length).to eq(2)
        end

        it "does not list any ended subscriptions" do
          get "/subscribers/#{subscriber.address}/subscriptions"
          ended_subscription = data[:subscriptions].detect { |s| s[:id] == subscription_2.id }
          expect(ended_subscription).to be_nil
        end
      end

      context "without an existing subscriber" do
        it "returns status code 404" do
          get "/subscribers/doesnotexist@example.com/subscriptions"
          expect(response.status).to eq(404)
        end
      end
    end
  end

  context "without authentication" do
    it "returns a 403" do
      get "/subscribers/test@example.com/subscriptions"
      expect(response.status).to eq(403)
    end
  end

  context "without authorisation" do
    it "returns a 403" do
      login_with_signin
      get "/subscribers/test@example.com/subscriptions"
      expect(response.status).to eq(403)
    end
  end
end
