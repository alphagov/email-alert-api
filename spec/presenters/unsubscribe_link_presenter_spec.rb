require "rails_helper"

RSpec.describe UnsubscribeLinkPresenter do
  describe ".call" do
    it "returns a presented unsubscribe link" do
      expected = "[Unsubscribe from Test title](http://www.dev.gov.uk/email/unsubscribe/abc123?title=Test%20title)"
      expect(described_class.call(id: "abc123", title: "Test title")).to eq(expected)
    end
  end
end
