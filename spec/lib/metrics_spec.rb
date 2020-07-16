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
end
