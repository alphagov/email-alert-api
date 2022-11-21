RSpec.describe SubscriberListQuery do
  let(:content_change_attributes) do
    {
      content_id: "37ac8e5c-331a-48fc-8ac0-d401579c3d30",
      tags: { policies: %w[eggs] },
      links: { policies: %w[f05dc04b-ca95-4cca-9875-a7591d055467], taxon_tree: %w[f05dc04b-ca95-4cca-9875-a7591d055448] },
      document_type: "travel_advice",
      email_document_supertype: "publications",
      government_document_supertype: "news_stories",
    }
  end

  subject { described_class.new(**content_change_attributes) }

  shared_examples "#list matching" do |tags_or_links|
    it { includes_subscriber_list(tags_or_links, document_type: "travel_advice") }
    it { excludes_subscriber_list(tags_or_links, document_type: "other") }
    it { includes_subscriber_list(tags_or_links, email_document_supertype: "publications") }
    it { excludes_subscriber_list(tags_or_links, email_document_supertype: "other") }
    it { includes_subscriber_list(tags_or_links, government_document_supertype: "news_stories") }
    it { excludes_subscriber_list(tags_or_links, government_document_supertype: "other") }

    it do
      includes_subscriber_list(
        tags_or_links,
        document_type: "travel_advice",
        email_document_supertype: "publications",
        government_document_supertype: "news_stories",
      )
    end

    it do
      excludes_subscriber_list(
        tags_or_links,
        document_type: "other",
        email_document_supertype: "publications",
        government_document_supertype: "news_stories",
      )
    end

    it do
      excludes_subscriber_list(
        tags_or_links,
        document_type: "travel_advice",
        email_document_supertype: "other",
        government_document_supertype: "news_stories",
      )
    end

    it do
      excludes_subscriber_list(
        tags_or_links,
        document_type: "travel_advice",
        email_document_supertype: "publications",
        government_document_supertype: "other",
      )
    end
  end

  context "when matching has tags fields" do
    it_behaves_like "#list matching", tags: { policies: { any: %w[eggs] } }, links: {}

    it "excluded when non-matching tags" do
      subscriber_list = create_subscriber_list(tags: { policies: { any: %w[apples] } })
      expect(subject.lists).not_to include(subscriber_list)
    end
  end

  context "when matching has links fields" do
    it_behaves_like "#list matching",
                    links: { policies: { any: %w[f05dc04b-ca95-4cca-9875-a7591d055467] },
                             taxon_tree: { all: %w[f05dc04b-ca95-4cca-9875-a7591d055448] } },
                    tags: {}

    it "excluded when non-matching links" do
      list_params = { links: { policies: { any: %w[f05dc04b-ca95-4cca-9875-a7591d055467] },
                               taxon_tree: { all: %w[f05dc04b-ca95-4cca-9875-a7591d055448 f05dc04b-ca95-4cca-9875-a7591d055446] } } }
      subscriber_list = create_subscriber_list(list_params)
      expect(subject.lists).not_to include(subscriber_list)
    end
  end

  context "when matching neither links or tags fields" do
    it_behaves_like "#list matching", links: {}, tags: {}
  end

  context "when a content_purpose_supergroup is provided" do
    let(:query_params) do
      {
        document_type: "travel_advice",
        tags: { content_purpose_supergroup: "guidance_and_regulation" },
      }
    end

    let(:query) { described_class.new(**default_list_attributes.merge(query_params)) }

    it "includes subscriber lists where the content_purpose_supergroup is set to the desired value" do
      list_params = { document_type: "travel_advice", tags: { content_purpose_supergroup: { any: %w[guidance_and_regulation] } } }
      subscriber_list = create_subscriber_list(default_list_attributes.merge(list_params))

      expect(query.lists).to include(subscriber_list)
    end

    it "includes subscriber lists even if the content_purpose_supergroup is nil, if the document_type is the same value" do
      list_params = { document_type: "travel_advice" }
      subscriber_list = create_subscriber_list(default_list_attributes.merge(list_params))

      expect(query.lists).to include(subscriber_list)
    end

    it "includes subscriber lists where the content_purpose_supergroup is set to the same value" do
      list_params = { tags: { content_purpose_supergroup: { any: %w[guidance_and_regulation] } } }
      subscriber_list = create_subscriber_list(default_list_attributes.merge(list_params))

      expect(query.lists).to include(subscriber_list)
    end

    it "excludes subscriber lists where the content_purpose_supergroup is set to a different value" do
      list_params = { document_type: "travel_advice", tags: { content_purpose_supergroup: { any: %w[news_and_communications] } } }
      subscriber_list = create_subscriber_list(default_list_attributes.merge(list_params))

      expect(query.lists).not_to include(subscriber_list)
    end

    it "excludes subscriber lists where the content_purpose_supergroup is set to the same value but the document type is different" do
      list_params = { tags: { content_purpose_supergroup: { any: %w[guidance_and_regulation] } }, document_type: "edition" }
      subscriber_list = create_subscriber_list(default_list_attributes.merge(list_params))

      expect(query.lists).not_to include(subscriber_list)
    end
  end

  context "when a content_purpose_subgroup is provided" do
    let(:query_params) { { tags: { content_purpose_subgroup: %w[updates_and_alerts] } } }
    let(:query) { described_class.new(**default_list_attributes.merge(query_params)) }

    it "includes subscriber lists where the content_purpose_subgroup is set to the desired value" do
      list_params = { tags: { content_purpose_subgroup: { any: %w[updates_and_alerts] } } }
      subscriber_list = create_subscriber_list(default_list_attributes.merge(list_params))

      expect(query.lists).to include(subscriber_list)
    end

    it "excludes subscriber lists where the content_purpose_subgroup is set to a different value" do
      list_params = { tags: { content_purpose_subgroup: { any: %w[speeches_and_statements] } } }
      subscriber_list = create_subscriber_list(default_list_attributes.merge(list_params))

      expect(query.lists).not_to include(subscriber_list)
    end
  end

  def create_subscriber_list(options)
    create(:subscriber_list, options)
  end

  let(:default_list_attributes) do
    {
      content_id: nil,
      links: {},
      tags: {},
      document_type: "",
      email_document_supertype: "",
      government_document_supertype: "",
    }
  end

  def includes_subscriber_list(tags_or_links, additional_list_attributes)
    subscriber_list = create_subscriber_list(default_list_attributes.merge(tags_or_links).merge(additional_list_attributes))
    expect(subject.lists).to include(subscriber_list)
  end

  def excludes_subscriber_list(tags_or_links, additional_list_attributes)
    subscriber_list = create_subscriber_list(default_list_attributes.merge(tags_or_links).merge(additional_list_attributes))
    expect(subject.lists).not_to include(subscriber_list)
  end
end
