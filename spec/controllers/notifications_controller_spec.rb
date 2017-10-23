require "rails_helper"

RSpec.describe NotificationsController, type: :controller do
  describe "#create" do
    let(:body) {
      <<-BODY.strip_heredoc
        <div>
          <div>Travel advice</div>
        </div>
      BODY
    }
    let(:expected_body) {
      <<-BODY.strip_heredoc
        <div>
          <div>Travel advice</div>
        </div>
        <span data-govuk-request-id="12345-67890"></span>
      BODY
    }
    let(:notification_params) {
      {
        subject: "This is a subject",
        body: body,
        tags: {
          topics: ["oil-and-gas/licensing"]
        },
        content_id: SecureRandom.uuid,
        title: "Travel advice",
        change_note: "This is a change note",
        description: "This is a description",
        public_updated_at: Time.now.to_s,
        email_document_supertype: "email document supertype",
        government_document_supertype: "government document supertype",
        document_type: "document type",
        publishing_app: "publishing app",
      }
    }
    let(:expected_notification_params) {
      notification_params
        .merge(links: {})
        .merge(body: expected_body.strip)
        .merge(govuk_request_id: '12345-67890')
    }

    before do
      allow(GdsApi::GovukHeaders).to receive(:headers)
        .and_return(govuk_request_id: "12345-67890")
    end

    it "serializes the tags and passes them to the NotificationWorker" do
      expect(NotificationWorker).to receive(:perform_async).with(
        expected_notification_params
      )

      post :create, params: notification_params.merge(format: :json)
    end

    it "allows an optional document_type parameter" do
      notification_params[:document_type] = "travel_advice"
      expect(NotificationWorker).to receive(:perform_async).with(
        expected_notification_params
      )

      post :create, params: notification_params.merge(format: :json)
    end

    it "allows an optional email_document_supertype parameter" do
      notification_params[:email_document_supertype] = "travel_advice"
      expect(NotificationWorker).to receive(:perform_async).with(
        expected_notification_params
      )

      post :create, params: notification_params.merge(format: :json)
    end

    it "allows an optional government_document_supertype parameter" do
      notification_params[:government_document_supertype] = "travel_advice"
      expect(NotificationWorker).to receive(:perform_async).with(
        expected_notification_params
      )

      post :create, params: notification_params.merge(format: :json)
    end
  end
end
