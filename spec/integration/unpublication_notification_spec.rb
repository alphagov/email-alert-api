RSpec.describe "Unpublication Notification", type: :request do
  let(:content_id) { SecureRandom.uuid }
  let(:params) {
    {
      content_id: content_id,
      notification_template: "default"
    }
  }
  let(:unpublication_notification_path) { "/unpublication_notification" }

  context "with authentication and authorisation" do
    before { login_with_internal_app }

    describe "POST" do
      it "returns 202" do
        post unpublication_notification_path, params: params
        expect(response.status).to eq(202)
      end

      it "creates an email" do
        expect { post unpublication_notification_path, params: params }.to change { Email.count }.by(1)
      end

      it "sends the email" do
        expect(SendEmailWorker).to receive(:perform_async_in_queue)
        post unpublication_notification_path, params: params
      end

      it "sends an email with the correct notification template" do
        post unpublication_notification_path, params: params
        expect(Email.count).to be 1

        expect(Email.last.body).to eq("@TODO")
      end

      it "removes the subscription list" do
        expect { post unpublication_notification_path, params: params }.to change { SubscriptionList.count }.by(-1)
      end
    end

    context "when the notification template does not exist" do
      it "returns 400" do
        post unpublication_notification_path, params: params
        expect(response.status).to eq(400)
      end
    end

    context "when the subscription list cannot be found" do
      it "returns 404 if the subscription list does not exists" do
        post unpublication_notification_path, params: params
        expect(response.status).to eq(202)
      end
    end
  end

  context "without authentication" do
    it "returns a 401" do
      without_login do
        post unpublication_notification_path, params: params
        expect(response.status).to eq(401)
      end
    end
  end

  context "without authorisation" do
    it "returns a 403" do
      login_with_signin
      post unpublication_notification_path, params: params
      expect(response.status).to eq(403)
    end
end
