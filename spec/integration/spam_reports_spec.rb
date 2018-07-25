RSpec.describe "Receiving a spam report", type: :request do
  let(:subscriber) { create(:subscriber) }
  let(:email) { create(:email, subscriber_id: subscriber.id) }
  let(:delivery_attempt) { create(:delivery_attempt, email_id: email.id) }
  let(:reference) { delivery_attempt.id }

  let(:permissions) { %w[signin status_updates] }
  let(:user) { create(:user, permissions: permissions) }
  before { login_as(user) }

  describe "#create" do
    let(:params) { { reference: reference } }
    let(:permissions) { %w[signin status_updates] }

    it "calls the unsubscribe service" do
      expect(UnsubscribeService).to receive(:spam_report!).with(delivery_attempt)

      post "/spam-reports", params: params
    end

    it "renders 204 no content" do
      post "/spam-reports", params: params

      expect(response.status).to eq(204)
      expect(response.body).to eq("")
    end

    it "marks the email as spam" do
      expect { post "/spam-reports", params: params }
        .to change { email.reload.marked_as_spam }
        .to eq(true)
    end

    context "when a user does not have 'status_updates' permission" do
      let(:permissions) { %w[signin] }

      it "renders 403" do
        post "/spam-reports", params: params

        expect(response.status).to eq(403)
      end
    end
  end
end
