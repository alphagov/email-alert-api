require "gds_api/test_helpers/account_api"

RSpec.describe "Subscribers GOV.UK account", type: :request do
  include GdsApi::TestHelpers::AccountApi

  let(:params) { { govuk_account_session: } }
  let(:govuk_account_session) { "session identifier" }

  let(:govuk_account_id) { "internal-user-id" }
  let(:email) { "test@example.com" }
  let(:email_verified) { true }

  let(:subscriber_email) { email }
  let!(:subscriber) { create(:subscriber, address: subscriber_email) }

  before do
    login_with_internal_app

    stub_account_api_user_info(
      id: govuk_account_id,
      email:,
      email_verified:,
    )
  end

  shared_examples "validates the user info response" do
    context "when the email address has not been verified" do
      let(:email_verified) { false }

      it "returns a 403" do
        post(path, params:)
        expect(response.status).to eq(403)
      end
    end

    context "when the email attribute is missing" do
      let(:email) { nil }

      it "returns a 403" do
        post(path, params:)
        expect(response.status).to eq(403)
      end
    end

    context "when the email_verified attribute is missing" do
      let(:email_verified) { nil }

      it "and returns a 403" do
        post(path, params:)
        expect(response.status).to eq(403)
      end
    end

    context "when the session is invalid" do
      before do
        stub_account_api_unauthorized_user_info
      end

      it "returns a 401" do
        post(path, params:)
        expect(response.status).to eq(401)
      end
    end

    context "when the govuk_account_session is missing" do
      let(:govuk_account_session) { nil }

      it "returns a 422" do
        post(path, params:)
        expect(response.status).to eq(422)
      end
    end
  end

  describe "fetching a user by GOV.UK Account ID" do
    let(:path) { "/subscribers/govuk-account/#{govuk_account_id}" }

    it "returns a 404" do
      get path
      expect(response.status).to eq(404)
    end

    context "when the subscriber is linked to a GOV.UK Account" do
      let(:subscriber) { create(:subscriber, address: subscriber_email, govuk_account_id:) }

      it "returns the subscriber" do
        get path
        expect(response.status).to eq(200)
        expect(data[:subscriber][:id]).to eq(subscriber.id)
        expect(data[:subscriber][:govuk_account_id]).to eq(subscriber.govuk_account_id)
      end
    end
  end

  describe "authenticating a user" do
    let(:path) { "/subscribers/govuk-account" }

    include_examples "validates the user info response"

    it "returns the subscriber" do
      post(path, params:)
      expect(response.status).to eq(200)
      expect(data[:subscriber][:id]).to eq(subscriber.id)
    end

    context "when the subscriber is linked to a GOV.UK Account" do
      let(:subscriber) { create(:subscriber, address: subscriber_email, govuk_account_id: "govuk-account-id") }

      it "returns the GOV.UK Account ID" do
        post(path, params:)
        expect(response.status).to eq(200)
        expect(data[:subscriber][:id]).to eq(subscriber.id)
        expect(data[:subscriber][:govuk_account_id]).to eq(subscriber.govuk_account_id)
      end
    end

    context "when the subscriber does not exist" do
      let(:subscriber_email) { "different@example.com" }

      it "creates the subscriber" do
        post(path, params:)
        expect(response.status).to eq(200)
        expect(data[:subscriber][:id]).not_to eq(subscriber.id)
      end
    end
  end

  describe "linking to an account" do
    let(:path) { "/subscribers/govuk-account/link" }

    include_examples "validates the user info response"

    it "returns the subscriber" do
      post(path, params:)
      expect(response.status).to eq(200)
      expect(data[:subscriber][:id]).to eq(subscriber.id)
    end

    it "records the GOV.UK Account ID" do
      post(path, params:)
      expect(response.status).to eq(200)
      expect(data[:subscriber][:govuk_account_id]).to eq(govuk_account_id)
    end

    it "does not send an email" do
      expect(SendEmailWorker).not_to receive(:perform_async_in_queue)
      post path, params:
    end

    context "when the subscriber has active subscriptions" do
      before do
        create(:subscription, subscriber:)
      end

      it "sends an email" do
        expect(SendEmailWorker).to receive(:perform_async_in_queue)
        post path, params:
      end
    end

    context "when the subscriber is already linked to a GOV.UK account" do
      let(:subscriber) { create(:subscriber, address: subscriber_email, govuk_account_id: "govuk-account-id") }

      it "replaces the old GOV.UK Account ID" do
        post(path, params:)
        expect(response.status).to eq(200)
        expect(data[:subscriber][:id]).to eq(subscriber.id)
        expect(data[:subscriber][:govuk_account_id]).to eq(govuk_account_id)
      end

      context "when the subscriber has active subscriptions" do
        before do
          create(:subscription, subscriber:)
        end

        it "does not send an email" do
          expect(SendEmailWorker).not_to receive(:perform_async_in_queue)
          post path, params:
        end
      end
    end

    context "when the subscriber does not exist" do
      let(:subscriber_email) { "different@example.com" }

      it "creates the subscriber" do
        post(path, params:)
        expect(response.status).to eq(200)
        expect(data[:subscriber][:id]).not_to eq(subscriber.id)
      end

      it "does not send an email" do
        expect(SendEmailWorker).not_to receive(:perform_async_in_queue)
        post path, params:
      end
    end
  end
end
