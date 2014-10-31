require "rails_helper"

RSpec.describe NotificationsController, type: :controller do
  describe "#create" do
    let(:notification_params) {
      {
        subject: "This is a subject",
        body: "This is a body",
        tags: {
          topics: ["oil-and-gas/licensing"]
        }
      }
    }

    it "serializes the tags and passes them to the NotificationWorker" do
      expect(NotificationWorker).to receive(:perform_async).with(notification_params.to_json)

      post :create, notification_params
    end
  end
end
