RSpec.describe FindExactQuery do
  context "when links are in the query" do
    it "not matched when query contains fewer keys than the subscriber_list" do
      create_subscriber_list(links: {
        people: { any: %w[uuid-888] },
        format: { any: %w[guide news_story] },
      })
      query = build_query(links: { people: { any: %w[uuid-888] } })
      expect(query.exact_match).to be_nil
    end

    it "not matched when query contains more keys than the subscriber_list" do
      create_subscriber_list(links: {
        people: { any: %w[uuid-888] },
        organisations: { any: %w[org-123 org-555] },
      })
      query = build_query(links: {
        people: { any: %w[uuid-888] },
        organisations: { any: %w[org-123 org-555] },
        foo: %w[bar],
      })
      expect(query.exact_match).to be_nil
    end

    it "not matched when matching keys, but different values for a key" do
      create_subscriber_list(links: {
        people: { any: %w[uuid-888] },
        organisations: { any: %w[org-123 org-555] },
      })
      query = build_query(links: {
        people: { any: %w[uuid-999] },
        organisations: { any: %w[org-456 org-666] },
      })
      expect(query.exact_match).to be_nil
    end

    it "matched when matching keys with matching values" do
      subscriber_list = create_subscriber_list(links: {
        people: { any: %w[uuid-888] },
        organisations: { any: %w[org-123 org-555] },
      })
      query = build_query(links: {
        people: { any: %w[uuid-888] },
        organisations: { any: %w[org-123 org-555] },
      })
      expect(query.exact_match).to eq(subscriber_list)
    end

    it "order of values for keys does not affect matching" do
      subscriber_list = create_subscriber_list(links: {
        people: { any: %w[uuid-888] },
        organisations: { any: %w[org-123 org-555] },
      })
      query = build_query(links: {
        organisations: { any: %w[org-555 org-123] },
        people: { any: %w[uuid-888] },
      })
      expect(query.exact_match).to eq(subscriber_list)
    end

    it "requires 'and' and 'any' operators to be correctly set" do
      subscriber_list = create_subscriber_list(links: {
        people: { all: %w[uuid-888 uuid-999], any: %w[uuid-777] },
        taxon_tree: { all: %w[taxon-123 taxon-555] },
      })
      query = build_query(links: {
        taxon_tree: { all: %w[taxon-123 taxon-555] },
        people: { all: %w[uuid-888 uuid-999], any: %w[uuid-777] },
      })
      expect(query.exact_match).to eq(subscriber_list)
    end

    it "does not match unless both operators are present" do
      subscriber_list = create_subscriber_list(links: {
        people: { all: %w[uuid-888], any: %w[uuid-777] },
      })
      bad_query = build_query(links: { people: { all: %w[uuid-888] } })
      good_query = build_query(links: { people: { all: %w[uuid-888], any: %w[uuid-777] } })
      expect(bad_query.exact_match).to be_nil
      expect(good_query.exact_match).to eq(subscriber_list)
    end

    it "matched when subscriber list has the same links" do
      query = build_query(links: { people: { any: %w[aa-11] }, taxon_tree: { all: %w[taxon] } })
      subscriber_list = create_subscriber_list(links: { people: { any: %w[aa-11] },
                                                        taxon_tree: { all: %w[taxon] } })
      expect(query.exact_match).to eq(subscriber_list)
    end

    it "matched when subscriber list has the same links and matching document_type" do
      query = build_query(
        links: { people: { any: %w[aa-11] },
                 taxon_tree: { all: %w[taxon] } },
        document_type: "travel_advice",
      )
      subscriber_list = create_subscriber_list(
        links: { people: { any: %w[aa-11] },
                 taxon_tree: { all: %w[taxon] } },
        document_type: "travel_advice",
      )
      expect(query.exact_match).to eq(subscriber_list)
    end

    it "matched when subscriber list has the same links and matching email_document_supertype" do
      query = build_query(links: { people: { any: %w[aa-11] } }, email_document_supertype: "publications")
      subscriber_list = create_subscriber_list(links: { people: { any: %w[aa-11] } }, email_document_supertype: "publications")
      expect(query.exact_match).to eq(subscriber_list)
    end

    it "matched when subscriber list has the same tags and matching content_id" do
      query = build_query(links: { people: { any: %w[uuid-937] } }, content_id: "11a51f5e-3f17-4516-87c7-02afba87ef40")
      subscriber_list = create_subscriber_list(links: { people: { any: %w[uuid-937] } }, content_id: "11a51f5e-3f17-4516-87c7-02afba87ef40")
      expect(query.exact_match).to eq(subscriber_list)
    end

    it "not matched when subscriber list has different links" do
      query = build_query(links: { people: { any: %w[aa-11] } })
      _subscriber_list = create_subscriber_list(links: { people: { any: %w[11-aa] } })
      expect(query.exact_match).to be_nil
    end

    it "not matched when subscriber list has no links" do
      query = build_query(links: { people: { any: %w[aa-11] } })
      _subscriber_list = create_subscriber_list
      expect(query.exact_match).to be_nil
    end

    it "not matched on tags if unable to match links - even if it would match" do
      query = build_query(links: { people: { any: %w[aa-11] } }, tags: { tribunal_decision_categories: { any: %w[tax] } })
      _subscriber_list = create_subscriber_list(links: { people: { any: %w[bb-22] } }, tags: { tribunal_decision_categories: { any: %w[tax] } })
      expect(query.exact_match).to be_nil
    end

    it "not matched on document type - even if they match" do
      query = build_query(links: { people: { any: %w[aa-11] } }, document_type: "travel_advice")
      _subscriber_list = create_subscriber_list(document_type: "travel_advice")
      expect(query.exact_match).to be_nil
    end

    it "not matched on content_id - even if they match" do
      query = build_query(links: { people: { any: %w[uuid-937] } }, content_id: "11a51f5e-3f17-4516-87c7-02afba87ef40")
      _subscriber_list = create_subscriber_list(content_id: "11a51f5e-3f17-4516-87c7-02afba87ef40")
      expect(query.exact_match).to be_nil
    end
  end

  context "when tags are in the query" do
    it "not matched when query contains fewer keys than the subscriber_list" do
      create_subscriber_list(tags: {
        tribunal_decision_categories: { any: %w[written-statements] },
        format: { any: %w[guide news_story] },
      })
      query = build_query(tags: { tribunal_decision_categories: { any: %w[written-statements] } })
      expect(query.exact_match).to be_nil
    end

    it "not matched when query contains more keys than the subscriber_list" do
      create_subscriber_list(tags: {
        tribunal_decision_judges: { any: %w[written-statements] },
        tribunal_decision_categories: { any: %w[reorganisation time-off] },
      })
      query = build_query(tags: {
        tribunal_decision_judges: { any: %w[written-statements] },
        tribunal_decision_categories: { any: %w[reorganisation time-off] },
        foo: %w[bar],
      })
      expect(query.exact_match).to be_nil
    end

    it "not matched when matching keys, but different values for each key" do
      create_subscriber_list(tags: {
        tribunal_decision_judges: { any: %w[written-statements] },
        tribunal_decision_categories: { any: %w[reorganisation time-off] },
      })
      query = build_query(tags: {
        tribunal_decision_judges: { any: %w[written-pay-statement] },
        tribunal_decision_categories: { any: %w[right-to-be-accompanied human-rights] },
      })
      expect(query.exact_match).to be_nil
    end

    it "matched when matching keys with matching values" do
      subscriber_list = create_subscriber_list(tags: {
        tribunal_decision_judges: { any: %w[written-statements] },
        tribunal_decision_categories: { any: %w[reorganisation time-off] },
      })
      query = build_query(tags: {
        tribunal_decision_judges: { any: %w[written-statements] },
        tribunal_decision_categories: { any: %w[reorganisation time-off] },
      })
      expect(query.exact_match).to eq(subscriber_list)
    end

    it "order of values for keys does not affect matching" do
      subscriber_list = create_subscriber_list(tags: {
        tribunal_decision_judges: { any: %w[written-statements] },
        tribunal_decision_categories: { any: %w[reorganisation time-off] },
      })
      query = build_query(tags: {
        tribunal_decision_categories: { any: %w[time-off reorganisation] },
        tribunal_decision_judges: { any: %w[written-statements] },
      })
      expect(query.exact_match).to eq(subscriber_list)
    end

    it "requires and and any operators to be correctly set" do
      subscriber_list = create_subscriber_list(tags: {
        tribunal_decision_judges: { all: %w[written-statements written-pay-statement], any: %w[national-minimum-wage] },
        subject: { all: %w[subject-123 subject-555] },
      })
      query = build_query(tags: {
        subject: { all: %w[subject-123 subject-555] },
        tribunal_decision_judges: { all: %w[written-statements written-pay-statement], any: %w[national-minimum-wage] },
      })
      expect(query.exact_match).to eq(subscriber_list)
    end

    it "requires both operators to be present" do
      subscriber_list = create_subscriber_list(tags: {
        tribunal_decision_judges: { all: %w[written-statements], any: %w[national-minimum-wage] },
      })
      bad_query = build_query(tags: { tribunal_decision_judges: { all: %w[written-statements] } })
      good_query = build_query(tags: { tribunal_decision_judges: { all: %w[written-statements], any: %w[national-minimum-wage] } })
      expect(bad_query.exact_match).to be_nil
      expect(good_query.exact_match).to eq(subscriber_list)
    end

    it "matched when subscriber tags has the same tags" do
      query = build_query(tags: { tribunal_decision_categories: { any: %w[fixed-term-regulations] },
                                  tribunal_decision_judges: { all: %w[taxon] } })
      subscriber_list = create_subscriber_list(tags: { tribunal_decision_categories: { any: %w[fixed-term-regulations] },
                                                       tribunal_decision_judges: { all: %w[taxon] } })
      expect(query.exact_match).to eq(subscriber_list)
    end

    it "matched when subscriber list has the same tags and matching document_type" do
      query = build_query(
        tags: { tribunal_decision_categories: { any: %w[fixed-term-regulations] },
                tribunal_decision_judges: { all: %w[taxon] } },
        document_type: "document_type",
      )
      subscriber_list = create_subscriber_list(
        tags: { tribunal_decision_categories: { any: %w[fixed-term-regulations] },
                tribunal_decision_judges: { all: %w[taxon] } },
        document_type: "document_type",
      )
      expect(query.exact_match).to eq(subscriber_list)
    end

    it "matched when subscriber list has the same tags and matching email_document_supertype" do
      query = build_query(tags: { tribunal_decision_categories: { any: %w[fixed-term-regulations] } }, email_document_supertype: "publications")
      subscriber_list = create_subscriber_list(tags: { tribunal_decision_categories: { any: %w[fixed-term-regulations] } }, email_document_supertype: "publications")
      expect(query.exact_match).to eq(subscriber_list)
    end

    it "matched when subscriber list has the same tags and matching content_id" do
      query = build_query(tags: { tribunal_decision_categories: { any: %w[fixed-term-regulations] } }, content_id: "11a51f5e-3f17-4516-87c7-02afba87ef40")
      subscriber_list = create_subscriber_list(tags: { tribunal_decision_categories: { any: %w[fixed-term-regulations] } }, content_id: "11a51f5e-3f17-4516-87c7-02afba87ef40")
      expect(query.exact_match).to eq(subscriber_list)
    end

    it "not matched when subscriber list has different tags" do
      query = build_query(tags: { tribunal_decision_categories: { any: %w[fixed-term-regulations] } })
      _subscriber_list = create_subscriber_list(tags: { tribunal_decision_categories: { any: %w[notice-appeal] } })
      expect(query.exact_match).to be_nil
    end

    it "not matched when subscriber list has no tags" do
      query = build_query(tags: { tribunal_decision_categories: %w[fixed-term-regulations] })
      _subscriber_list = create_subscriber_list
      expect(query.exact_match).to be_nil
    end

    it "not matched on document type - even if they match" do
      query = build_query(tags: { tribunal_decision_categories: { any: %w[fixed-term-regulations] } }, document_type: "travel_advice")
      _subscriber_list = create_subscriber_list(document_type: "travel_advice")
      expect(query.exact_match).to be_nil
    end

    it "not matched on content_id - even if they match" do
      query = build_query(tags: { tribunal_decision_categories: { any: %w[fixed-term-regulations] } }, content_id: "11a51f5e-3f17-4516-87c7-02afba87ef40")
      _subscriber_list = create_subscriber_list(content_id: "11a51f5e-3f17-4516-87c7-02afba87ef40")
      expect(query.exact_match).to be_nil
    end
  end

  it "matched on document type only" do
    query = build_query(document_type: "travel_advice")
    subscriber_list = create_subscriber_list(document_type: "travel_advice")
    expect(query.exact_match).to eq(subscriber_list)
  end

  it "not matched on different document type" do
    query = build_query(tags: { tribunal_decision_categories: { any: %w[fixed-term-regulations] } }, document_type: "travel_advice")
    _subscriber_list = create_subscriber_list(document_type: "other")
    expect(query.exact_match).to be_nil
  end

  it "matched on email document supertype only" do
    query = build_query(email_document_supertype: "publications")
    subscriber_list = create_subscriber_list(email_document_supertype: "publications")
    expect(query.exact_match).to eq(subscriber_list)
  end

  it "matched on email document supertype and government document supertype" do
    query = build_query(email_document_supertype: "publications", government_document_supertype: "news_stories")
    subscriber_list = create_subscriber_list(email_document_supertype: "publications", government_document_supertype: "news_stories")
    expect(query.exact_match).to eq(subscriber_list)
  end

  it "not matched when email document supertype matched and government document supertype not matched" do
    query = build_query(email_document_supertype: "publications", government_document_supertype: "news_stories")
    _subscriber_list = create_subscriber_list(email_document_supertype: "publications", government_document_supertype: "other")
    expect(query.exact_match).to be_nil
  end

  it "matched on content_id only" do
    query = build_query(content_id: "11a51f5e-3f17-4516-87c7-02afba87ef40")
    subscriber_list = create_subscriber_list(content_id: "11a51f5e-3f17-4516-87c7-02afba87ef40")
    expect(query.exact_match).to eq(subscriber_list)
  end

  it "not matched on different content_id" do
    query = build_query(content_id: "11a51f5e-3f17-4516-87c7-02afba87ef40")
    _subscriber_list = create_subscriber_list(content_id: "ef8a3fd2-2b15-4c0e-a2d4-2a34187f337a")
    expect(query.exact_match).to be_nil
  end

  it "matched on blank content_id" do
    query = build_query(content_id: "")
    subscriber_list = create_subscriber_list(content_id: nil)
    expect(query.exact_match).to eq(subscriber_list)
  end

  def build_query(params = {})
    defaults = {
      content_id: nil,
      tags: {},
      links: {},
      document_type: "",
      email_document_supertype: "",
      government_document_supertype: "",
    }

    described_class.new(**defaults.merge(params))
  end

  def create_subscriber_list(params = {})
    defaults = {
      content_id: nil,
      tags: {},
      links: {},
      document_type: "",
      email_document_supertype: "",
      government_document_supertype: "",
    }
    create(:subscriber_list, defaults.merge(params))
  end
end
