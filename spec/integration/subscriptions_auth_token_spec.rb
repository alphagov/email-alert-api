RSpec.describe "Subscriptions auth token", type: :request do
  include TokenHelpers

  before { login_with_internal_app }

  describe "creating an auth token" do
    let(:path) { "/subscriptions/auth-token" }
    let(:address) { "test@example.com" }
    let(:frequency) { "daily" }

    let(:topic_id) do
      create(:subscriber_list, slug: "business-tax-corporation-tax").slug
    end

    let(:params) do
      {
        address:,
        topic_id:,
        frequency:,
      }
    end

    it "returns 200" do
      post(path, params:)
      expect(response.status).to eq(200)
    end

    context "when we're provided with no email address" do
      let(:address) { nil }

      it "returns a 422" do
        post(path, params:)
        expect(response.status).to eq(422)
      end
    end

    context "when we're provided with a badly formatted email address" do
      let(:address) { "wrong.bad" }

      it "returns a 422" do
        post(path, params:)
        expect(response.status).to eq(422)
      end
    end

    context "when we're provided with no topic_id" do
      let(:topic_id) { nil }

      it "returns a 422" do
        post(path, params:)
        expect(response.status).to eq(422)
      end
    end

    context "when the subscriber list does not exist" do
      let(:topic_id) { "does-not-exist" }

      it "returns a 404" do
        post(path, params:)
        expect(response.status).to eq(404)
      end
    end

    context "when we're provided with no frequency" do
      let(:frequency) { nil }

      it "returns a 422" do
        post(path, params:)
        expect(response.status).to eq(422)
      end
    end

    context "when we're provided with a bad frequency" do
      let(:frequency) { "something_else" }

      it "returns a 422" do
        post(path, params:)
        expect(response.status).to eq(422)
      end
    end

    it "creates an email" do
      expect { post path, params: }.to change { Email.count }.by(1)
    end

    it "sends the email" do
      expect(SendEmailWorker).to receive(:perform_async_in_queue)
      post path, params:
    end

    it "sends an email with the correct token" do
      post(path, params:)
      expect(Email.count).to be 1

      expect(decrypt_token_from_link(Email.last.body)).to eq(
        "address" => address,
        "topic_id" => topic_id,
        "frequency" => frequency,
      )
    end
  end
end
