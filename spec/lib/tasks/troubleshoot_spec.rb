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

  describe "deliver_to_subscriber" do
    it "queues a test email to a specified subscriber" do
      subscriber = create :subscriber
      expect(DeliveryRequestWorker).to receive(:perform_async_in_queue)

      expect { Rake::Task["troubleshoot:deliver_to_subscriber"].invoke(subscriber.id.to_s) }
        .to change { Email.count }.by 1
    end
  end

  describe "deliver_to_test_email" do
    it "queues a test email to a test email address" do
      expect(DeliveryRequestWorker).to receive(:perform_async_in_queue)

      expect { Rake::Task["troubleshoot:deliver_to_test_email"].invoke("foo@bar.com") }
        .to change { Email.count }.by 1
    end
  end

  describe "resend_failed_emails:by_id" do
    it "queues specified failed emails to resend" do
      email = create :email, status: :failed

      expect(DeliveryRequestWorker).to receive(:perform_async_in_queue)
        .with(email.id, queue: :delivery_immediate)

      expect { Rake::Task["troubleshoot:resend_failed_emails:by_id"].invoke(email.id.to_s) }
        .to output.to_stdout
    end
  end
end
