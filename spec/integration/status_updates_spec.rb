RSpec.describe "Receiving a status update for an email", type: :request do
  let!(:delivery_attempt) do
    create(
      :delivery_attempt,
      reference: "ref-123",
      status: "sending",
      email: create(:email, address: "foo@bar.com"),
    )
  end

  let!(:subscriber) { create(:subscriber, address: "foo@bar.com") }

  before { create_list(:subscription, 3, subscriber: subscriber) }

  it "sets the delivery attempt's status via a worker" do
    params = { reference: "ref-123", status: "delivered" }
    post "/status-updates", params: params

    expect(response.status).to eq(204)

    delivery_attempt.reload
    expect(delivery_attempt.status).to eq("delivered")
  end

  context "when the status is 'permanent-failure'" do
    it "unsubscribes the subscriber" do
      params = { reference: "ref-123", status: "permanent-failure" }
      post "/status-updates", params: params

      subscriber.reload

      expect(subscriber.address).to be_nil
      expect(subscriber.subscriptions).to be_empty
    end

    context "and the subscriber has already been unsubscribed" do
      before { UnsubscribeService.subscriber!(subscriber) }

      it "does not error" do
        params = { reference: "ref-123", status: "permanent-failure" }
        expect { post "/status-updates", params: params }.not_to raise_error
      end
    end
  end
end
