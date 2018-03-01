RSpec.describe "Receiving a status update", type: :request do
  let(:reference) { "b6589b2b-8f8e-457b-9ddf-237b62438ad1" }

  let!(:delivery_attempt) do
    create(:delivery_attempt, reference: reference, status: "sending")
  end

  let(:permissions) { %w[signin status_updates] }
  let(:user) { create(:user, permissions: permissions) }
  before { login_as(user) }

  describe "#create" do
    let(:params) { { reference: reference, status: "delivered" } }
    let(:permissions) { %w[signin status_updates] }

    it "calls the status update service" do
      expect(StatusUpdateService).to receive(:call).with(
        reference: reference,
        status: "delivered",
        user: user,
      )

      post "/status-updates", params: params
    end

    it "renders 204 no content" do
      post "/status-updates", params: params

      expect(response.status).to eq(204)
      expect(response.body).to eq("")
    end

    it "updates the delivery attempt" do
      expect { post "/status-updates", params: params }
        .to change { delivery_attempt.reload.status }
        .to eq("delivered")
    end

    context "when a user does not have 'status_updates' permission" do
      let(:permissions) { %w[signin] }

      it "renders 403" do
        post "/status-updates", params: params

        expect(response.status).to eq(403)
      end
    end

    context "when a status attempt arrives for an already handled delivery attempt" do
      before { delivery_attempt.update!(status: "delivered") }

      it "renders 409" do
        post "/status-updates", params: params

        expect(response.status).to eq(409)
      end
    end

    context "when a status attempt arrives with an unknown status" do
      it "renders 422" do
        post "/status-updates", params: params.merge(status: "unknown")

        expect(response.status).to eq(422)
      end
    end
  end
end
