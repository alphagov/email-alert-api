require 'rails_helper'

RSpec.describe FindExactMatch do
  before do
    @list_with_tags = create(
      :subscriber_list,
      tags: {
        topics: ["oil-and-gas/licensing"],
        organisations: ["environment-agency", "hm-revenue-customs"]
      },
      document_type: "policy",
    )
  end

  it "requires all tag types in the document to be present in the list" do
    found_lists = described_class.new(query_field: :tags)
      .call({ topics: ["oil-and-gas/licensing"] }, "policy")
    expect(found_lists).to eq([])
  end

  it "requires all tag types in the list to be present in the document" do
    found_lists = described_class.new(query_field: :tags)
      .call({
        topics: ["oil-and-gas/licensing"],
        organisations: ["environment-agency", "hm-revenue-customs"],
        foo: ["bar"]
      }, "policy")
    expect(found_lists).to eq([])
  end

  it "requires the a match on the document type" do
    found_lists = described_class.new(query_field: :tags)
      .call({
        topics: ["oil-and-gas/licensing"],
        organisations: ["environment-agency", "hm-revenue-customs"]
      }, "something_else")
    expect(found_lists).to eq([])
  end

  it "requires all tag types in the list to be present in the document" do
    list_with_links = create(
      :subscriber_list,
      links: { topics: ["uuid-888"] },
      document_type: "policy",
    )

    found_by_tags = described_class.new(query_field: :tags)
      .call({
        topics: ["oil-and-gas/licensing"],
        organisations: ["environment-agency", "hm-revenue-customs"]
      }, "policy")

    expect(found_by_tags).to eq([@list_with_tags])

    found_by_links = described_class.new(query_field: :links)
      .call({
        topics: ["uuid-888"]
      }, "policy")

    expect(found_by_links).to eq([list_with_links])
  end
end
