RSpec.describe "Receiving a status update", type: :request do
  describe "#create" do
    let(:status) { "delivered" }
    let(:permissions) { %w[signin status_updates] }
    let(:user) { create(:user, permissions:) }
    let(:params) do
      {
        reference: SecureRandom.uuid,
        status:,
        to: "test.user@example.com",
      }
    end

    before { login_as(user) }

    it "responds with no content" do
      post "/status-updates", params: params

      expect(response).to have_http_status(:no_content)
      expect(response.body).to eq("")
    end

    context "when a user does not have 'status_updates' permission" do
      let(:permissions) { %w[signin] }

      it "responds with a forbidden" do
        post "/status-updates", params: params

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when a status attempt arrives with an permanent-failure status" do
      let(:status) { "permanent-failure" }

      it "can unsubscribe all of a subscribers subscriptions by email id" do
        subscriber = create(:subscriber, address: params[:to])

        expect(UnsubscribeAllService).to receive(:call).with(subscriber, :non_existent_email)

        post "/status-updates", params: params

        expect(response).to be_successful
      end

      it "can cope if the subscriber doesn't exist" do
        expect(UnsubscribeAllService).not_to receive(:call)

        post "/status-updates", params: params

        expect(response).to be_successful
      end
    end

    context "when a status attempt arrives with an unknown status" do
      let(:status) { "unknown" }

      it "responds with 422" do
        post "/status-updates", params: params

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
