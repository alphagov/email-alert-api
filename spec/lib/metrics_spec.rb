RSpec.describe Metrics do
  before do
    allow(GovukStatsd).to receive(:count)
  end

  describe ".content_change_emails" do
    it "sends stats for a batch of content change emails" do
      content_change = build(:content_change, publishing_app: "app", document_type: "type")
      expect(GovukStatsd).to receive(:count).with("content_change_emails.publishing_app.app.immediate", 1)
      expect(GovukStatsd).to receive(:count).with("content_change_emails.document_type.type.immediate", 1)
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
end
