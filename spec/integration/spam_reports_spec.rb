RSpec.describe "Receiving a spam report", type: :request do
  let(:subscriber) { create(:subscriber) }
  let(:permissions) { %w[signin status_updates] }
  let(:user) { create(:user, permissions:) }

  before { login_as(user) }

  describe "#create" do
    let(:params) { { to: subscriber.address } }
    let(:permissions) { %w[signin status_updates] }

    context "when there is a subscriber associated with the recipient email address" do
      it "unsubscribes the user" do
        post("/spam-reports", params:)
        expect(subscriber.active_subscriptions).to be_empty
      end

      it "renders 204 no content" do
        post("/spam-reports", params:)

        expect(response.status).to eq(204)
        expect(response.body).to eq("")
      end
    end

    context "when there is no subscriber associated with the recipient email address" do
      it "renders 204 no content" do
        post "/spam-reports", params: { to: "not-a-subscriber@example.com" }

        expect(response.status).to eq(204)
        expect(response.body).to eq("")
      end
    end

    context "when a user does not have 'status_updates' permission" do
      let(:permissions) { %w[signin] }

      it "renders 403" do
        post("/spam-reports", params:)

        expect(response.status).to eq(403)
      end
    end
  end
end
