require "rails_helper"

RSpec.describe GovukRequestId, :insert do
  before do
    allow(GdsApi::GovukHeaders).to receive(:headers)
      .and_return(govuk_request_id: "12345-67890")
  end

  context "when the body is nil" do
    it "doesn't do anything" do
      expect(described_class.insert(nil)).to eq(nil)
    end
  end

  context "when the body is empty" do
    let(:body) { "" }
    it "doesn't do anything" do
      expect(described_class.insert(body)).to eq("")
    end
  end

  context "when the body doesn't contain html" do
    let(:body) { "Some email content" }
    it "doesn't do anything" do
      expect(described_class.insert(body)).to eq(body)
    end
  end

  context "when the body is html" do
    let(:body) { "<p><span>Some body content</span></p>" }
    let(:expected_body) do
      %Q(<p><span>Some body content</span></p><span data-govuk-request-id="12345-67890"></span>)
    end

    it "adds a data attribute to the first child element" do
      expect(described_class.insert(body)).to eq(expected_body)
    end
  end
end
