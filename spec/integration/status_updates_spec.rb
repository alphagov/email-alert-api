RSpec.describe "Receiving a status update", type: :request do
  let(:delivery_attempt) { create(:delivery_attempt, status: "sending") }
  let(:reference) { delivery_attempt.id }

  let(:permissions) { %w[signin status_updates] }
  let(:user) { create(:user, permissions: permissions) }
  before { login_as(user) }

  describe "#create" do
    let(:params) do
      {
        sent_at: Time.parse("2017-05-14T12:15:30.000000Z"),
        completed_at: Time.parse("2017-05-14T12:15:30.000000Z"),
        reference: reference,
        status: "delivered"
      }
    end

    let(:permissions) { %w[signin status_updates] }

    it "calls the status update service" do
      expect(StatusUpdateService).to receive(:call).with(
        sent_at: Time.parse("2017-05-14T12:15:30.000000Z"),
        completed_at: Time.parse("2017-05-14T12:15:30.000000Z"),
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

    context "without sent_at" do
      let(:params_without_sent_at) { params.reject { |k, _v| k == :sent_at } }

      it "updates the delivery attempt" do
        expect(StatusUpdateService).to receive(:call).with(
          sent_at: nil,
          completed_at: Time.parse("2017-05-14T12:15:30.000000Z"),
          reference: reference,
          status: "delivered",
          user: user,
        )

        post "/status-updates", params: params_without_sent_at
      end

      it "renders 204 no content" do
        post "/status-updates", params: params_without_sent_at

        expect(response.status).to eq(204)
        expect(response.body).to eq("")
      end

      it "updates the delivery attempt" do
        expect { post "/status-updates", params: params_without_sent_at }
          .to change { delivery_attempt.reload.status }
          .to eq("delivered")
      end
    end
  end
end
