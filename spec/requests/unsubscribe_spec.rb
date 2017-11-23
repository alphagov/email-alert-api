require "rails_helper"

RSpec.describe "/unsubscribe/<uuid>", type: :request do
  describe "POST" do
    context "when the subscription exists" do
      let(:subscription) { create(:subscription) }

      before do
        post "/unsubscribe/#{subscription.uuid}"
      end

      it "deletes the subscription" do
        expect(Subscription.count).to eq(0)
      end

      it "responds with a 200 status" do
        expect(response.status).to eq(200)
      end
    end

    context "when the subscription doesn't exist" do
      before do
        post "/unsubscribe/123"
      end

      it "responds with a 404 status" do
        expect(response.status).to eq(404)
      end
    end
  end
end
