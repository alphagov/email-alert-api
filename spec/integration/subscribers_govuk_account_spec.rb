require "gds_api/test_helpers/account_api"

RSpec.describe "Subscribers GOV.UK account", type: :request do
  include GdsApi::TestHelpers::AccountApi

  before { login_with_internal_app }

  describe "authenticating a user" do
    let(:path) { "/subscribers/govuk-account" }
    let(:params) { { govuk_account_session: govuk_account_session } }
    let(:govuk_account_session) { "session identifier" }

    let(:email) { "test@example.com" }
    let(:email_verified) { true }

    let(:subscriber_email) { email }
    let!(:subscriber) { create(:subscriber, address: subscriber_email) }

    before do
      stub_account_api_has_attributes(
        attributes: %i[email email_verified],
        values: {
          "email" => email,
          "email_verified" => email_verified,
        }.compact,
      )
    end

    it "returns the subscriber" do
      post path, params: params
      expect(response.status).to eq(200)
      expect(data[:subscriber][:id]).to eq(subscriber.id)
    end

    context "when the subscriber does not exist" do
      let(:subscriber_email) { "different@example.com" }

      it "creates the subscriber" do
        post path, params: params
        expect(response.status).to eq(200)
        expect(data[:subscriber][:id]).not_to eq(subscriber.id)
      end
    end

    context "when the email address has not been verified" do
      let(:email_verified) { false }

      it "returns a 403" do
        post path, params: params
        expect(response.status).to eq(403)
      end
    end

    context "when the email attribute is missing" do
      let(:email) { nil }

      it "returns a 403" do
        post path, params: params
        expect(response.status).to eq(403)
      end
    end

    context "when the email_verified attribute is missing" do
      let(:email_verified) { nil }

      it "and returns a 403" do
        post path, params: params
        expect(response.status).to eq(403)
      end
    end

    context "when the session is invalid" do
      before do
        stub_account_api_unauthorized_has_attributes(attributes: %i[email email_verified])
      end

      it "returns a 401" do
        post path, params: params
        expect(response.status).to eq(401)
      end
    end

    context "when the govuk_account_session is missing" do
      let(:govuk_account_session) { nil }

      it "returns a 422" do
        post path, params: params
        expect(response.status).to eq(422)
      end
    end
  end
end
