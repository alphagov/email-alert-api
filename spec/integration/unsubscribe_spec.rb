RSpec.describe "Unsubscribing", type: :request do
  context "with authentication and authorisation" do
    before do
      login_as(create(:user, permissions: %w[internal_app]))
    end

    describe "POST" do
      context "when the subscription exists" do
        let(:subscription) { create(:subscription) }

        before do
          post "/unsubscribe/#{subscription.id}"
        end

        it "deletes the subscription" do
          expect(Subscription.active.count).to eq(0)
        end

        it "responds with a 204 status" do
          expect(response.status).to eq(204)
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

  context "without authentication" do
    it "returns a 403" do
      post "/unsubscribe/123"
      expect(response.status).to eq(403)
    end
  end

  context "without authorisation" do
    it "returns a 403" do
      login_with_signin
      post "/unsubscribe/123"
      expect(response.status).to eq(403)
    end
  end
end
