RSpec.describe "troubleshoot" do
  describe "get_notifications_from_notify" do
    it "outputs the status of notifications with a specified reference" do
      stub_request(:get, "http://fake-notify.com/v2/notifications?reference=reference&template_type=email")
        .to_return(body: attributes_for(:client_notifications_collection)[:body].to_json)

      expect { Rake::Task["troubleshoot:get_notifications_from_notify"].invoke("reference") }
        .to output.to_stdout
    end
  end

  describe "get_notifications_from_notify_by_email_id" do
    it "outputs the status of notifications with a specified email ID" do
      expect { Rake::Task["troubleshoot:get_notifications_from_notify_by_email_id"].invoke("1") }
        .to output.to_stdout
    end
  end
end
