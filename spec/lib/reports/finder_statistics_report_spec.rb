require "gds_api/test_helpers/content_store"

RSpec.describe Reports::FinderStatisticsReport do
  include GdsApi::TestHelpers::ContentStore

  let(:govuk_path) { "/cma-cases" }

  let(:expected) do
    <<~OUTPUT

      Lists created from this finder
       - Example List (0 active subscribers)

      Resulting in:
       - notified immediately: 0
       - notified next day:    0
       - notified at weekend:  0
       - notified total:       0
    OUTPUT
  end

  before do
    content_item = content_item_for_base_path(govuk_path).merge(
      "document_type" => "finder",
      "links" => { "email_alert_signup" => { "withdrawn" => false } },
      "details" => { "filter" => { "format" => "cma_case" } },
    )
    stub_content_store_has_item(govuk_path, content_item)
    create(:subscriber_list, title: "Example List", tags: { format: { any: %w[cma_case] } })
  end

  it "returns data around active lists for the given date" do
    expect(described_class.new(govuk_path).call).to eq expected
  end
end
