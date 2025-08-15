require "gds_api/test_helpers/content_store"

RSpec.describe SubscriberListsByContentItemQuery do
  include GdsApi::TestHelpers::ContentStore

  describe ".call" do
    let(:govuk_path) { "/cma-cases" }

    it "includes lists that match on content_id" do
      content_item = content_item_for_base_path(govuk_path).merge("content_id" => "f05dc04b-ca95-4cca-9875-a7591d055467")
      list = create(:subscriber_list, content_id: content_item["content_id"])
      result = described_class.new(content_item).call

      expect(result).to contain_exactly(list)
    end

    it "includes lists that match on tags" do
      content_item = content_item_for_base_path(govuk_path).merge("tags" => {
        "tribunal_decision_categories" => "public-interest-disclosure",
      })
      list = create(:subscriber_list, content_id: content_item["content_id"])
      result = described_class.new(content_item).call

      expect(result).to contain_exactly(list)
    end

    it "includes lists that match on taxon_tree links" do
      content_item = content_item_for_base_path(govuk_path).merge("links" => {
        "taxon_tree" => %w[f05dc04b-ca95-4cca-9875-a7591d055448],
      })
      list = create(:subscriber_list, content_id: content_item["content_id"])
      result = described_class.new(content_item).call

      expect(result).to contain_exactly(list)
    end

    it "includes lists that match on taxons links" do
      content_item = content_item_for_base_path(govuk_path).merge("links" => {
        "taxons" => [{
          "content_id" => "f05dc04b-ca95-4cca-9875-a7591d055448",
          "links" => {
            "parent_taxons" => ["content_id": "f05dc04b-ca95-4cca-9875-a7591d055448"],
          },
        }],
      })
      list = create(:subscriber_list, content_id: content_item["content_id"])
      result = described_class.new(content_item).call

      expect(result).to contain_exactly(list)
    end

    it "does not return links in list if taxons array is empty" do
      content_item = content_item_for_base_path(govuk_path).merge("links" => {
        "taxons" => [],
      })
      create(:subscriber_list, content_id: content_item["content_id"])

      result = described_class.new(content_item).call

      expect(result.first["links"]).to be_empty
    end

    it "includes lists that match on parent staxons links" do
      content_item = content_item_for_base_path(govuk_path).merge("links" => {
        "taxons" => [
          "links" => {
            "parent_taxons" => ["content_id" => "f05dc04b-ca95-4cca-9875-a7591d055448"],
          },
        ],
      })
      list = create(:subscriber_list, content_id: content_item["content_id"])
      result = described_class.new(content_item).call

      expect(result).to contain_exactly(list)
    end

    it "does not return links in list if parent_taxons key is not present" do
      content_item = content_item_for_base_path(govuk_path).merge("links" => {
        "taxons" => [
          "links" => {},
        ],
      })
      create(:subscriber_list, content_id: content_item["content_id"])

      result = described_class.new(content_item).call

      expect(result.first["links"]).to be_empty
    end

    it "does not return links in list if parent_taxons array is empty" do
      content_item = content_item_for_base_path(govuk_path).merge("links" => {
        "taxons" => [
          "links" => {
            "parent_taxons" => [],
          },
        ],
      })
      create(:subscriber_list, content_id: content_item["content_id"])

      result = described_class.new(content_item).call

      expect(result.first["links"]).to be_empty
    end

    it "includes lists that match on document_type" do
      content_item = content_item_for_base_path(govuk_path).merge("document_type" => "travel_advice")
      list = create(:subscriber_list, content_id: content_item["content_id"])
      result = described_class.new(content_item).call

      expect(result).to contain_exactly(list)
    end

    it "includes lists that match on email_document_supertype" do
      content_item = content_item_for_base_path(govuk_path).merge("email_document_supertype" => "publications")
      list = create(:subscriber_list, content_id: content_item["content_id"])
      result = described_class.new(content_item).call

      expect(result).to contain_exactly(list)
    end

    it "includes lists that match on government_document_supertype" do
      content_item = content_item_for_base_path(govuk_path).merge("government_document_supertype" => "news_stories")
      list = create(:subscriber_list, content_id: content_item["content_id"])
      result = described_class.new(content_item).call

      expect(result).to contain_exactly(list)
    end
  end
end
