require "gds_api/test_helpers/content_store"

RSpec.describe SubscriberListsForFinderQuery do
  include GdsApi::TestHelpers::ContentStore

  describe ".call" do
    let(:govuk_path) { "/cma-cases" }
    let!(:content_item) do
      content_item_for_base_path(govuk_path).merge(
        "document_type" => "finder",
        "links" => { "email_alert_signup" => { "withdrawn" => false } },
        "details" => { "filter" => { "format" => "cma_case" } },
      )
    end

    before do
      stub_content_store_has_item(govuk_path, content_item)
    end

    it "can match a list" do
      list = create(:subscriber_list, tags: { format: { any: %w[cma_case] } })

      result = described_class.new(govuk_path:).call
      expect(result).to contain_exactly(list)
    end

    context "with non-finder" do
      let!(:non_finder_content_item) do
        content_item_for_base_path(govuk_path).merge("document_type" => "external_content")
      end

      before do
        stub_content_store_has_item(govuk_path, non_finder_content_item)
      end

      it "raises a NotAFinderError" do
        create(:subscriber_list, tags: { format: { any: %w[cma_case] } })

        expect { described_class.new(govuk_path:).call }.to raise_error(SubscriberListsForFinderQuery::NotAFinderError)
      end
    end
  end
end
