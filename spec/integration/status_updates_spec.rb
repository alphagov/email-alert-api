require "rails_helper"

RSpec.describe "Receiving a status update for an email", type: :request do
  let!(:delivery_attempt) do
    FactoryGirl.create(
      :delivery_attempt,
      reference: "ref-123",
      status: "sending",
    )
  end

  it "sets the delivery attempt's status via a worker" do
    params = { reference: "ref-123", status: "delivered" }
    post "/status_updates", params: params

    expect(response.status).to eq(202)
    expect(response.body).to eq("queued for processing")

    delivery_attempt.reload
    expect(delivery_attempt.status).to eq("delivered")
  end
end
