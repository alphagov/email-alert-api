require "rails_helper"

RSpec.describe SubscriptionsController, type: :controller do
  let(:data) { JSON.parse(response.body).deep_symbolize_keys }

  it "responds with JSON" do
    post :create, format: :json

    expect(response.status).to eq(201)
    expect(response.content_type).to eq("application/json")
    expect { data }.to_not raise_error
  end
end
