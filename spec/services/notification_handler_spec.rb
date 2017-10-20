require 'rails_helper'

RSpec.describe NotificationHandler do
  let(:params) {
    {
      subject: "This is a subject",
      body: "body stuff",
      tags: {
        topics: ["oil-and-gas/licensing"]
      },
      links: {
        organisations: [
          "c380ea42-5d91-41cc-b3cd-0a4cfe439461"
        ]
      },
      content_id: "afe78383-6b27-45a4-92ae-a579e416373a",
      title: "Travel advice",
      change_note: "This is a change note",
      description: "This is a description",
      base_path: "/government/things",
      public_updated_at: Time.now.to_s,
      email_document_supertype: "email document supertype",
      government_document_supertype: "government document supertype",
      document_type: "document type",
      publishing_app: "publishing app",
      govuk_request_id: "request-id",
    }
  }

  describe ".call" do
    it "calls create on Notification" do
      expect(Notification).to receive(:create!).with(
        content_id: params[:content_id],
        title: params[:title],
        change_note: params[:change_note],
        description: params[:description],
        base_path: params[:base_path],
        links: params[:links],
        tags: params[:tags],
        public_updated_at: params[:public_updated_at],
        email_document_supertype: params[:email_document_supertype],
        government_document_supertype: params[:government_document_supertype],
        govuk_request_id: params[:govuk_request_id],
        document_type: params[:document_type],
        publishing_app: params[:publishing_app],
      ).and_return(double(id: 1))

      allow(Email).to receive(:create_from_params!)

      NotificationHandler.call(params: params)
    end

    it "calls create on Email" do
      notification = create(:notification)
      allow(Notification).to receive(:create!).and_return(
        notification
      )

      expect(Email).to receive(:create_from_params!).with(
        title: "Travel advice",
        description: "This is a description",
        change_note: "This is a change note",
        base_path: "/government/things",
        notification_id: notification.id,
      )

      NotificationHandler.call(params: params)
    end
  end
end
