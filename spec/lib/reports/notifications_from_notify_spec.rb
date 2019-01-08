RSpec.describe Reports::NotificationsFromNotify do
  describe "notifications report" do
    let(:options) {
      {
        "template_type" => "email",
        "reference"     => reference
      }
    }

    let(:reference) { "ref_123" }
    let(:request_path) { URI.encode_www_form(options) }
    let!(:notifications_collection) { build :client_notifications_collection }

    context "when passing a valid reference" do
      before do
        stub_request(
          :get,
          "http://fake-notify.com/v2/notifications?#{request_path}"
        ).to_return(body: mocked_response.to_json)
      end

      let(:mocked_response) {
        attributes_for(
          :client_notifications_collection
        )[:body].merge(options)
      }

      it "prints details about one notification" do
        # We generate a unique reference for each email sent so we should only
        # expect to return one notification within the collection
        client = instance_double("Notifications::Client")
        notification = notifications_collection.collection.first
        allow(client).to receive(:get_notifications).and_return(notifications_collection)
        described_class.call(reference)

        expect { described_class.call(reference) }
        .to output(
          <<~TEXT
            Query Notify for emails with the reference #{reference}
            -------------------------------------------
            Notification ID: #{notification.id}
            Status: #{notification.status}
            created_at: #{notification.created_at}
            sent_at: #{notification.sent_at}
            completed_at: #{notification.completed_at}
          TEXT
        ).to_stdout
      end
    end
  end
end
