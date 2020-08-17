RSpec.describe "support" do
  describe "hash_to_table" do
    it "converts a hash to table markdown" do
      hash = [{ foo: "bar", baz: 12_345 }, { foo: "Long bar", baz: 12 }]
      expected_markdown = <<~MARKDOWN
        | Foo      | Baz   |
        | bar      | 12345 |
        | Long bar | 12    |
      MARKDOWN
      expect(hash_to_table(hash)).to eq(expected_markdown)
    end

    it "converts non-string values to string" do
      hash = [{ timestamp: Time.zone.parse("2020-06-29 15:18:48") }]
      expected_markdown = <<~MARKDOWN
        | Timestamp                 |
        | 2020-06-29 15:18:48 +0100 |
      MARKDOWN
      expect(hash_to_table(hash)).to eq(expected_markdown)
    end
  end

  describe "get_notifications_from_notify_by_email_id" do
    it "outputs the status of notifications with a specified email ID" do
      expect { Rake::Task["support:get_notifications_from_notify_by_email_id"].invoke("1") }
        .to output.to_stdout
    end
  end

  describe "deliver_to_test_email" do
    it "queues a test email to a test email address" do
      expect(DeliveryRequestWorker).to receive(:perform_async_in_queue)

      expect { Rake::Task["support:deliver_to_test_email"].invoke("foo@bar.com") }
        .to change { Email.count }.by 1
    end
  end

  describe "resend_failed_emails:by_id" do
    it "queues specified failed emails to resend" do
      email = create :email, status: :failed

      expect(DeliveryRequestWorker).to receive(:perform_async_in_queue)
        .with(email.id, queue: :delivery_immediate_high)

      expect { Rake::Task["support:resend_failed_emails:by_id"].invoke(email.id.to_s) }
        .to output.to_stdout
    end
  end

  describe "resend_failed_emails:by_date" do
    it "queues specified failed emails to resend" do
      email = create :email, status: :failed

      expect(DeliveryRequestWorker).to receive(:perform_async_in_queue)
        .with(email.id, queue: :delivery_immediate_high)

      from = (email.created_at - 1.day).iso8601
      to = (email.created_at + 1.day).iso8601
      expect { Rake::Task["support:resend_failed_emails:by_date"].invoke(from, to) }
        .to output.to_stdout
    end
  end
end
