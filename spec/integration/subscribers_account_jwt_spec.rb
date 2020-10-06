RSpec.describe "Subscribers from account JWT", type: :request do
  let(:private_key) { OpenSSL::PKey::EC.new("prime256v1").tap(&:generate_key) }
  let(:public_key) { OpenSSL::PKey::EC.new(private_key).tap { |key| key.private_key = nil } }

  let(:email) { "text@example.com" }
  let(:email_verified) { true }

  let(:jwt) do
    payload = { email: email, email_verified: email_verified }
    JWT.encode payload.compact, private_key, "ES256"
  end

  let(:params) { { jwt: jwt }.compact }
  let(:path) { "/subscribers/account-jwt" }

  before do
    allow(Rails.application.secrets).to receive(:accounts_jwt_public_key).and_return(public_key)
  end

  context "with authentication and authorisation" do
    before do
      login_with_internal_app
    end

    it "returns the subscriber details" do
      post path, params: params
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)["subscriber"]).to_not be_nil
    end

    context "JWT signature does not match" do
      let(:public_key) do
        bad_private_key = OpenSSL::PKey::EC.new("prime256v1").tap(&:generate_key)
        OpenSSL::PKey::EC.new(bad_private_key).tap { |key| key.private_key = nil }
      end

      it "returns a 403" do
        post path, params: params
        expect(response.status).to eq(403)
        expect(JSON.parse(response.body)["details"]).to eq("could not decode jwt")
      end
    end

    context "address is not verified" do
      let(:email_verified) { false }

      it "returns a 403" do
        post path, params: params
        expect(response.status).to eq(403)
        expect(JSON.parse(response.body)["details"]).to eq("email address not verified")
      end
    end

    context "missing the JWT" do
      let(:jwt) { nil }

      it "returns a 422" do
        post path, params: params
        expect(response.status).to eq(422)
      end
    end
  end

  context "without authentication" do
    it "returns a 401" do
      without_login do
        post path
        expect(response.status).to eq(401)
      end
    end
  end
end
