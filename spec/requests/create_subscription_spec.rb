require "rails_helper"
require "base64"

RSpec.describe "Creating a subscription", type: :request do
  it "returns a 201" do
    post "/subscriptions", params: {}, headers: json_headers

    expect(response.status).to eq(201)
  end
end
