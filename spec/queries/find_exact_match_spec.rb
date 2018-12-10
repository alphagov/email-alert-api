RSpec.describe FindExactMatch do
  let!(:list_with_tags) do
    create(
      :subscriber_list,
      tags: {
        topics: { any: ["oil-and-gas/licensing"] },
        organisations: { any: ["environment-agency", "hm-revenue-customs"] }
      },
      links: {
        topics: { any: ["uuid-888"] },
        organisations: { any: ["org-123", "org-555"] }
      },
      document_type: "policy",
    )
  end
  let!(:list_with_all_and_any) do
    create(
      :subscriber_list,
      tags: {
        topics: { all: ["oil-and-gas/licensing", 'something/else'] },
        taxon_tree: { all: ["ship-crew-health-and-safety", "mental-health-service-reform"], any: ["product-safety"] }
      },
      links: {
        topics: { all: ["uuid-888", "uuid-999"], any: ["uuid-777"] },
        taxon_tree: { all: ["taxon-123", "taxon-555"] }
      },
      document_type: "policy",
      )
  end

  context 'when matching on tags' do
    it "not matched when query contains fewer keys than the subscriber_list" do
      found_lists = described_class.new(query_field: :tags)
        .call(topics:  { any: ["oil-and-gas/licensing"] })
      expect(found_lists).to eq([])
    end

    it "not matched when query contains more keys than the subscriber_list" do
      found_lists = described_class.new(query_field: :tags)
        .call(topics:  { any: ["oil-and-gas/licensing"] },
          organisations:  { any: ["environment-agency", "hm-revenue-customs"] },
          foo:  { any: %w[bar] })
      expect(found_lists).to eq([])
    end

    it "not matched when matching keys, but different values for each key" do
      found_lists = described_class.new(query_field: :tags)
        .call(topics:  { any: ["oil-and-gas/conservation"] },
          organisations:  { any: ["environment-agency", "hm-revenue-customs"] })
      expect(found_lists).to eq([])
    end

    it "matched when matching keys with matching values" do
      found_lists = described_class.new(query_field: :tags)
        .call(topics: { any: ["oil-and-gas/licensing"] },
          organisations:  { any: ["environment-agency", "hm-revenue-customs"] })
      expect(found_lists).to eq([list_with_tags])
    end

    it "order of values for keys does not affect matching" do
      found_lists = described_class.new(query_field: :tags)
        .call(topics:  { any: ["oil-and-gas/licensing"] },
          organisations:  { any: ["hm-revenue-customs", "environment-agency"] })
      expect(found_lists).to eq([list_with_tags])
    end

    it "requires and and any operators to be correctly set" do
      found_lists = described_class.new(query_field: :tags)
                      .call(topics: { all: ["oil-and-gas/licensing", 'something/else'] },
                            taxon_tree: { all: ["ship-crew-health-and-safety", "mental-health-service-reform"], any: ["product-safety"] })
      expect(found_lists).to eq([list_with_all_and_any])
    end

    it "requires both operators to be present" do
      found_lists = described_class.new(query_field: :tags)
                      .call(topics: { all: ["oil-and-gas/licensing", 'something/else'] },
                            taxon_tree: { all: ["ship-crew-health-and-safety", "mental-health-service-reform"] })
      expect(found_lists).to be_empty
    end
  end

  context 'when matching on links' do
    it "not matched when query contains less keys than the subscriber_list" do
      found_lists = described_class.new(query_field: :links)
        .call(topics:  { any: ["uuid-888"] })
      expect(found_lists).to eq([])
    end

    it "not matched when query contains more keys than the subscriber_list" do
      found_lists = described_class.new(query_field: :links)
        .call(topics:  { any: ["uuid-888"] },
          organisations:  { any: ["org-123", "org-555"] },
          foo: %w[bar])
      expect(found_lists).to eq([])
    end


    it "not matched when matching keys, but different values for each key" do
      found_lists = described_class.new(query_field: :links)
        .call(topics:  { any: ["oil-and-gas/conservation"] },
          organisations:  { any: ["org-123", "org-555"] })
      expect(found_lists).to eq([])
    end

    it "matched when matching keys with matching values" do
      found_lists = described_class.new(query_field: :links)
        .call(topics:  { any: ["uuid-888"] },
          organisations:  { any: ["org-123", "org-555"] })
      expect(found_lists).to eq([list_with_tags])
    end

    it "order of values for keys does not affect matching" do
      found_lists = described_class.new(query_field: :links)
        .call(topics:  { any: ["uuid-888"] },
          organisations:  { any: ["org-555", "org-123"] })
      expect(found_lists).to eq([list_with_tags])
    end

    it "requires and and any operators to be correctly set" do
      found_lists = described_class.new(query_field: :links)
                      .call(topics: { all: ["uuid-888", "uuid-999"], any: ["uuid-777"] },
                            taxon_tree: { all: ["taxon-123", "taxon-555"] })
      expect(found_lists).to eq([list_with_all_and_any])
    end

    it "requires both operators to be present" do
      found_lists = described_class.new(query_field: :links)
                      .call(topics: { all: ["uuid-888", "uuid-999"] },
                            taxon_tree: { all: ["taxon-123", "taxon-555"] })
      expect(found_lists).to be_empty
    end
  end
end
