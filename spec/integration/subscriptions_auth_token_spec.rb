RSpec.describe "Subscriptions auth token", type: :request do
  before { login_with_internal_app }

  describe "creating an auth token" do
    let(:path) { "/subscriptions/auth-token" }

    it "returns 200" do
      post path
      expect(response.status).to eq(200)
    end
  end
end
