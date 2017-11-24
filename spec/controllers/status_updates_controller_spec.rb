require "rails_helper"

RSpec.describe StatusUpdatesController, type: :controller do
  let!(:delivery_attempt) do
    create(:delivery_attempt, reference: "ref-123", status: "sending")
  end

  describe "#create" do
    it "queues a job for processing" do
      expect(StatusUpdateWorker).to receive(:perform_async).with(
        reference: "ref-123",
        status: "delivered",
      )

      post :create, params: { reference: "ref-123", status: "delivered" }
    end

    it "renders 202 accepted" do
      post :create, params: { reference: "ref-123", status: "delivered" }

      expect(response.status).to eq(202)
      expect(response.body).to eq("queued for processing")
    end
  end
end
