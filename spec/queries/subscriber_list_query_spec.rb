RSpec.describe SubscriberListQuery do
  let(:content_id) { "37ac8e5c-331a-48fc-8ac0-d401579c3d30" }
  let(:tags) { { policies: %w[eggs] } }
  let(:links) { { policies: %w[f05dc04b-ca95-4cca-9875-a7591d055467], taxon_tree: %w[f05dc04b-ca95-4cca-9875-a7591d055448] } }
  let(:document_type) { "travel_advice" }
  let(:email_document_supertype) { "publications" }
  let(:government_document_supertype) { "news_stories" }

  let(:content_change_attributes) do
    {
      content_id:,
      tags: {},
      links: {},
      document_type: "",
      email_document_supertype: "",
      government_document_supertype: "",
    }
  end

  let(:subscriber_list_attributes) do
    {
      content_id: nil,
      links: {},
      tags: {},
      document_type: "",
      email_document_supertype: "",
      government_document_supertype: "",
    }
  end

  let(:document_type_attributes) do
    {
      document_type:,
      email_document_supertype:,
      government_document_supertype:,
    }
  end

  def create_subscriber_list(options = {})
    create(:subscriber_list, subscriber_list_attributes.merge(**options))
  end

  def build_content_change(options = {})
    content_change_attributes.merge(**options)
  end

  context "when a subscriber_list has document types only" do
    it "includes lists that match on all document types" do
      content_change = build_content_change(document_type_attributes)
      list = create_subscriber_list(document_type_attributes)
      query = described_class.new(**content_change)

      expect(query.lists).to include(list)
    end

    it "includes lists that match on document_type" do
      content_change = build_content_change(document_type:)
      list = create_subscriber_list(document_type:)
      query = described_class.new(**content_change)

      expect(query.lists).to include(list)
    end

    it "includes lists that match on email_document_supertype" do
      content_change = build_content_change(email_document_supertype:)
      list = create_subscriber_list(email_document_supertype:)
      query = described_class.new(**content_change)

      expect(query.lists).to include(list)
    end

    it "includes lists that match on government_document_supertype" do
      content_change = build_content_change(government_document_supertype:)
      list = create_subscriber_list(government_document_supertype:)
      query = described_class.new(**content_change)

      expect(query.lists).to include(list)
    end

    it "excludes lists that don't match on document type" do
      content_change = build_content_change(document_type_attributes)
      list = create_subscriber_list(document_type_attributes.merge(document_type: "other"))
      query = described_class.new(**content_change)

      expect(query.lists).not_to include(list)
    end

    it "excludes lists that don't match on email_document_supertype" do
      content_change = build_content_change(document_type_attributes)
      list = create_subscriber_list(document_type_attributes.merge(email_document_supertype: "other"))
      query = described_class.new(**content_change)

      expect(query.lists).not_to include(list)
    end

    it "excludes lists that don't match on government_document_supertype" do
      content_change = build_content_change(document_type_attributes)
      list = create_subscriber_list(document_type_attributes.merge(government_document_supertype: "other"))
      query = described_class.new(**content_change)

      expect(query.lists).not_to include(list)
    end
  end

  context "when a subscriber_list has document types and tags" do
    let(:content_change_tags) { { policies: %w[eggs] } }
    let(:list_tags) { { policies: { any: %w[eggs] } } }

    it "includes lists that match on document types and tags" do
      content_change = build_content_change(document_type_attributes.merge(tags: content_change_tags))
      list = create_subscriber_list(document_type_attributes.merge(tags: list_tags))
      query = described_class.new(**content_change)

      expect(query.lists).to include(list)
    end

    it "excludes lists that match on document type but do not match on tags" do
      content_change = build_content_change(document_type_attributes.merge(tags: content_change_tags))
      list = create_subscriber_list(document_type_attributes.merge(tags: { policies: { any: %w[cheese] } }))
      query = described_class.new(**content_change)

      expect(query.lists).not_to include(list)
    end

    it "exludes lists that match on tags but do not match on document types" do
      unmatched_document_type_attributes = document_type_attributes.merge(government_document_supertype: "other")

      content_change = build_content_change(document_type_attributes.merge(tags: content_change_tags))
      list = create_subscriber_list(unmatched_document_type_attributes.merge(tags: list_tags))
      query = described_class.new(**content_change)
      expect(query.lists).not_to include(list)
    end
  end

  context "when a subscriber_list has document types and links" do
    let(:policy_id) { "f05dc04b-ca95-4cca-9875-a7591d055467" }
    let(:taxon_id) { "f05dc04b-ca95-4cca-9875-a7591d055448" }

    let(:content_change_links) do
      {
        policies: [policy_id],
        taxon_tree: [taxon_id],
      }
    end

    let(:subscriber_list_links) do
      {
        policies: { any: [policy_id] },
        taxon_tree: { all: [taxon_id] },
      }
    end

    it "includes lists that match on document types and link" do
      content_change = build_content_change(document_type_attributes.merge(links: content_change_links))
      list = create_subscriber_list(document_type_attributes.merge(links: subscriber_list_links))
      query = described_class.new(**content_change)

      expect(query.lists).to include(list)
    end

    it "excludes lists that match on document type but do not match on link" do
      content_change = build_content_change(document_type_attributes.merge(links: content_change_links))
      list = create_subscriber_list(document_type_attributes.merge(links: { policies: { any: %w[random-content-id] } }))
      query = described_class.new(**content_change)

      expect(query.lists).not_to include(list)
    end

    it "exludes lists that match on links but do not match on document types" do
      content_change = build_content_change(document_type_attributes.merge(links: content_change_links))
      unmatched_document_type_attributes = document_type_attributes.merge(document_type: "other")
      list = create_subscriber_list(unmatched_document_type_attributes.merge(links: subscriber_list_links))
      query = described_class.new(**content_change)

      expect(query.lists).not_to include(list)
    end
  end

  context "when a content change has a content_purpose_supergroup" do
    let(:content_purpose_supergroup) { %w[guidance_and_regulation] }

    it "includes lists where the content_purpose_supergroup is set to the desired value" do
      content_change = build_content_change(document_type_attributes.merge(tags: { content_purpose_supergroup: }))
      list = create_subscriber_list(document_type_attributes.merge(tags: { content_purpose_supergroup: { any: content_purpose_supergroup } }))
      query = described_class.new(**content_change)

      expect(query.lists).to include(list)
    end

    it "includes lists even if the content_purpose_supergroup is nil, if the document_type is the same value" do
      content_change = build_content_change(document_type_attributes.merge(tags: { content_purpose_supergroup: }))
      list = create_subscriber_list(document_type_attributes)
      query = described_class.new(**content_change)

      expect(query.lists).to include(list)
    end

    it "excludes lists where the content_purpose_supergroup is set to a different value" do
      content_change = build_content_change(document_type_attributes.merge(tags: { content_purpose_supergroup: }))
      list = create_subscriber_list(document_type_attributes.merge(tags: { content_purpose_supergroup: { any: %w[news_and_communications] } }))
      query = described_class.new(**content_change)

      expect(query.lists).not_to include(list)
    end

    it "excludes lists where the content_purpose_supergroup is set to the same value but the document type is different" do
      content_change = build_content_change(document_type_attributes.merge(tags: { content_purpose_supergroup: }))
      unmatched_document_type_attributes = document_type_attributes.merge(government_document_supertype: "other")
      list = create_subscriber_list(unmatched_document_type_attributes.merge(tags: { content_purpose_supergroup: { any: content_purpose_supergroup } }))
      query = described_class.new(**content_change)

      expect(query.lists).not_to include(list)
    end
  end

  context "when a content change has a content_purpose_subgroup" do
    let(:content_purpose_subgroup) { %w[updates_and_alerts] }

    it "includes lists where the content_purpose_subgroup is set to the desired value" do
      content_change = build_content_change(document_type_attributes.merge(tags: { content_purpose_subgroup: }))
      list = create_subscriber_list(document_type_attributes.merge(tags: { content_purpose_subgroup: { any: content_purpose_subgroup } }))
      query = described_class.new(**content_change)

      expect(query.lists).to include(list)
    end

    it "excludes lists where the content_purpose_subgroup is set to a different value" do
      content_change = build_content_change(document_type_attributes.merge(tags: { content_purpose_subgroup: }))
      list = create_subscriber_list(document_type_attributes.merge(tags: { content_purpose_subgroup: { any: %w[speeches] } }))
      query = described_class.new(**content_change)

      expect(query.lists).not_to include(list)
    end
  end

  context "when a subscriber_list has content id only" do
    let(:no_match_content_id) { "9376121a-b7bc-4521-b973-b63a72e0f1cf" }

    it "includes lists where the content id matches" do
      content_change = build_content_change
      list = create_subscriber_list(content_id:)
      query = described_class.new(**content_change)

      expect(query.lists).to include(list)
    end

    it "excludes lists where the content id does not match" do
      content_change = build_content_change
      list = create_subscriber_list(content_id: no_match_content_id)
      query = described_class.new(**content_change)

      expect(query.lists).not_to include(list)
    end
  end
end
