RSpec.describe Metrics do
  describe ".content_change_emails" do
    it "sends stats for a batch of content change emails" do
      content_change = build(:content_change, publishing_app: "app", document_type: "type")
      expect(PrometheusMetrics).to receive(:observe).with("immediate_content_change_batch_emails", 1, { publishing_app: "app", document_type: "type" })

      described_class.content_change_emails(content_change, 1)
    end
  end

  describe ".content_change_created" do
    it "increments the counter for the number of content changes created" do
      expect(PrometheusMetrics).to receive(:observe).with("content_changes_created", 1)

      described_class.content_change_created
    end
  end

  describe ".unsubscribed" do
    it "increments the counter when a user is unsubscribed with the reason" do
      expect(PrometheusMetrics).to receive(:observe).with("unsubscribed_reason", 1, { reason: "unsubscribed" })

      described_class.unsubscribed("unsubscribed")
    end
  end

  describe ".sent_to_notify_successfully" do
    it "increments the counter when there is a successful email send request to Notify" do
      expect(PrometheusMetrics).to receive(:observe).with("notify_email_send_request_success", 1)

      described_class.sent_to_notify_successfully
    end
  end

  describe ".failed_to_send_to_notify" do
    it "increments the counter when there is a failed attempt to email send request to Notify" do
      expect(PrometheusMetrics).to receive(:observe).with("notify_email_send_request_failure", 1)

      described_class.failed_to_send_to_notify
    end
  end

  describe ".sent_to_pseudo_successfully" do
    it "increments the counter when there is a successful pseudo email send request" do
      expect(PrometheusMetrics).to receive(:observe).with("pseudo_email_send_request_success", 1)

      described_class.sent_to_pseudo_successfully
    end
  end

  describe ".message_created" do
    it "increments the counter when a message is created" do
      expect(PrometheusMetrics).to receive(:observe).with("message_created", 1)

      described_class.message_created
    end
  end

  describe ".content_change_created_until_email_sent" do
    it "sends data on time between content change created and email sent" do
      sent_time = Time.zone.now
      created_time = sent_time - sent_time.min
      difference = (sent_time - created_time) * 1000

      expect(PrometheusMetrics).to receive(:observe).with("content_change_created_until_email_sent", difference)

      described_class.content_change_created_until_email_sent(created_time, sent_time)
    end
  end

  describe ".email_send_request" do
    it "sends data on when a email send request and to which provider" do
      expect(PrometheusMetrics).to receive(:observe).with("email_send_request", 1, { provider: "notify" })

      described_class.email_send_request("notify")
    end
  end
end
