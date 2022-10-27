RSpec.describe "Subscriptions", type: :request do
  context "with authentication and authorisation" do
    before do
      login_with_internal_app
    end

    context "with an existing subscription" do
      let(:subscriber_list) { create(:subscriber_list) }
      let(:subscriber) { create(:subscriber, address: "test@example.com") }
      let!(:subscription) { create(:subscription, subscriber_list:, subscriber:, frequency: :immediately) }
      let(:frequency) { "daily" }

      it "lets you query the subscription" do
        get "/subscriptions/#{subscription.id}"
        check_json_is_valid
      end

      it "lets you query for a more recent subscription" do
        get "/subscriptions/#{subscription.id}/latest"
        check_json_is_valid
      end
    end

    context "with an existing subscription and an expired matching subscription" do
      let(:subscriber_list) { create(:subscriber_list) }
      let(:subscriber) { create(:subscriber, address: "test@example.com") }
      let!(:old_subscription) { create(:subscription, :ended, subscriber_list:, subscriber:, created_at: 1000.days.ago) }
      let!(:new_subscription) { create(:subscription, subscriber_list:, subscriber:) }

      it "returns a more recent subscription if it exists" do
        get "/subscriptions/#{old_subscription.id}/latest"
        expect(response.status).to eq(200)
        expect(data[:subscription][:id]).to eq new_subscription.id
      end
    end

    context "without an existing subscription" do
      it "raises a 404 querying a non-existing subscription" do
        get "/subscriptions/3c926708-ecfa-4165-889d-c0d45cbdc01c"
        expect(response.status).to eq(404)
      end
    end
  end
end

def check_json_is_valid
  expect(response.status).to eq(200)
  expect(data[:subscription].keys).to match_array(%i[
    id
    subscriber_list
    subscriber
    created_at
    updated_at
    ended_at
    ended_reason
    ended_email_id
    frequency
    source
  ])
end
