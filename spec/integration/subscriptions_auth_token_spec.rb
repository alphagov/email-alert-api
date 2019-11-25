RSpec.describe "Subscriptions auth token", type: :request do
  before { login_with_internal_app }

  describe "creating an auth token" do
    let(:path) { "/subscriptions/auth-token" }
    let(:address) { "test@example.com" }
    let(:topic_id) { "business-tax-corporation-tax" }
    let(:frequency) { "weekly" }
    let(:params) do
      {
        address: address,
        topic_id: topic_id,
        frequency: frequency,
      }
    end

    it "returns 200" do
      post path, params: params
      expect(response.status).to eq(200)
    end

    context "when we're provided with no email address" do
      let(:address) { nil }

      it "returns a 422" do
        post path, params: params
        expect(response.status).to eq(422)
      end
    end
    context "when we're provided with a badly formatted email address" do
      let(:address) { "wrong.bad" }

      it "returns a 422" do
        post path, params: params
        expect(response.status).to eq(422)
      end
    end
    context "when we're provided with no topic_id" do
      let(:topic_id) { nil }

      it "returns a 422" do
        post path, params: params
        expect(response.status).to eq(422)
      end
    end
    context "when we're provided with no frequency" do
      let(:frequency) { nil }

      it "returns a 422" do
        post path, params: params
        expect(response.status).to eq(422)
      end
    end
    context "when we're provided with a bad frequency" do
      let(:frequency) { "something_else" }

      it "returns a 422" do
        post path, params: params
        expect(response.status).to eq(422)
      end
    end
  end
end
