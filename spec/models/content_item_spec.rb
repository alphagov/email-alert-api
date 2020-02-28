require "rails_helper"
require "gds_api/test_helpers/content_store"

RSpec.describe ContentItem do
  include ::GdsApi::TestHelpers::ContentStore

  describe "title" do
    it "gets the title from the content store" do
      stub_content_store_has_item(
        "/redirected/path",
        {
          "base_path" => "/redirected/path",
          "title" => "redirected title",
        }.to_json,
      )
      expect(ContentItem.new("/redirected/path").title).to eq("redirected title")
    end
    it "returns a default value as the title if the base path does not exist" do
      stub_content_store_does_not_have_item("/redirected/path")
      expect(ContentItem.new("/redirected/path").title).to eq(ContentItem::DEFAULT)
    end
    it "returns  a default value as the title if the title does not exist" do
      stub_content_store_has_item(
        "/redirected/path",
        {
          "base_path" => "/redirected/path",
          "title" => nil,
        }.to_json,
      )
      expect(ContentItem.new("/redirected/path").title).to eq(ContentItem::DEFAULT)
    end
  end
  describe "url" do
    it "returns the full URL" do
      expect(ContentItem.new("/redirected/path").url).to eq("http://www.dev.gov.uk/redirected/path")
    end
  end

  describe "content_store_data" do
    it "raises and exception if the response base_path differs from the requested item" do
      stub_content_store_has_item(
        "/requested/path",
        {
          "base_path" => "/different/path",
        }.to_json,
      )

      expect {
        ContentItem.new("/requested/path").content_store_data
      }.to raise_error(ContentItem::RedirectDetected)
    end
  end
end
