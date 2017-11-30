require "rails_helper"

RSpec.describe SubscriptionsController, type: :controller do
  let(:data) { JSON.parse(response.body).deep_symbolize_keys }

  it "requires an address parameter" do
    expect {
      post :create, params: { subscribable_id: 10 }
    }.to raise_error(ActionController::ParameterMissing)
  end

  it "requires a subscribable_id parameter" do
    expect {
      post :create, params: { address: "test@example.com" }
    }.to raise_error(ActionController::ParameterMissing)
  end

  it "responds with JSON" do
    post :create, params: { subscribable_id: 10, address: "test@example.com" }, format: :json

    expect(response.status).to eq(201)
    expect(response.content_type).to eq("application/json")
    expect { data }.to_not raise_error
  end
end
