require "rails_helper"

RSpec.describe StatusUpdatesController, type: :controller do
  let!(:delivery_attempt) do
    create(:delivery_attempt, reference: "ref-123", status: "sending")
  end

  describe "#create" do
    let(:params) { { reference: "ref-123", status: "delivered" } }

    context "when a user does not have 'status_updates' permission" do
      before do
        login_as(create(:user, permissions: %w[signin]))
      end

      it "renders 403" do
        post :create, params: params

        expect(response.status).to eq(403)
      end
    end

    context "when a user does not have 'status_updates' permission" do
      before do
        login_as(create(:user, permissions: %w[signin status_updates]))
      end

      it "calls the status update service" do
        expect(StatusUpdateService).to receive(:call).with(
          reference: "ref-123",
          status: "delivered",
        )

        post :create, params: params
      end

      it "renders 204 no content" do
        post :create, params: params

        expect(response.status).to eq(204)
        expect(response.body).to eq("")
      end

      it "updates the delivery attempt" do
        expect { post :create, params: params }
          .to change { delivery_attempt.reload.status }
          .to eq("delivered")
      end
    end
  end
end
