RSpec.describe "Subscribers auth token", type: :request do
  include TokenHelpers

  before { login_with_internal_app }

  describe "creating an auth token" do
    let(:path) { "/subscribers/auth-token" }
    let(:address) { "test@example.com" }
    let(:destination) { "/test" }
    let(:params) do
      {
        address:,
        destination:,
      }
    end
    let!(:subscriber) { create(:subscriber, address: "test@example.com") }

    it "returns 201" do
      post(path, params:)
      expect(response.status).to eq(201)
    end

    it "returns subscriber details" do
      post(path, params:)
      expect(data[:subscriber][:id]).to eq(subscriber.id)
    end

    it "sends an email" do
      expect(SendEmailWorker).to receive(:perform_async_in_queue)
      post path, params:
    end

    it "sends an email with the correct token" do
      post(path, params:)
      expect(Email.count).to be 1

      expect(decrypt_token_from_link(Email.last.body)).to eq(
        "subscriber_id" => subscriber.id,
      )
    end

    context "when the user is linked to a GOV.UK Account" do
      before { subscriber.update!(govuk_account_id: "42") }

      it "returns a 403" do
        post(path, params:)
        expect(response.status).to eq(403)
      end
    end

    context "when it's a user we didn't previously know" do
      before { subscriber.delete }

      it "returns a 404" do
        post(path, params:)
        expect(response.status).to eq(404)
      end
    end

    context "when we're provided with a bad email address" do
      let(:address) { "bad-address" }

      it "returns a 422" do
        post(path, params:)
        expect(response.status).to eq(422)
      end
    end

    context "when we're provided with no email address" do
      let(:address) { nil }

      it "returns a 422" do
        post(path, params:)
        expect(response.status).to eq(422)
      end
    end

    context "when we're not given a destination" do
      let(:destination) { nil }

      it "returns a 422" do
        post(path, params:)
        expect(response.status).to eq(422)
      end
    end

    context "when we're given a bad destination" do
      let(:destination) { "http://example.com/test" }

      it "returns a 422" do
        post(path, params:)
        expect(response.status).to eq(422)
      end
    end
  end
end
