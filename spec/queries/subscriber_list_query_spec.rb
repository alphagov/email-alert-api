RSpec.describe SubscriberListQuery do
  subject do
    described_class.new(
      tags: { policies: %w[eggs] },
      links: { policies: %w[11aa], taxon_tree: %w[taxon1 taxon2] },
      document_type: 'travel_advice',
      email_document_supertype: 'publications',
      government_document_supertype: 'news_stories',
    )
  end

  shared_examples '#links matching' do |tags_or_links|
    it { is_included_in_links tags_or_links, document_type: 'travel_advice' }
    it { is_excluded_from_links tags_or_links, document_type: 'other' }
    it { is_included_in_links tags_or_links, email_document_supertype: 'publications' }
    it { is_excluded_from_links tags_or_links, email_document_supertype: 'other' }
    it { is_included_in_links tags_or_links, government_document_supertype: 'news_stories' }
    it { is_excluded_from_links tags_or_links, government_document_supertype: 'other' }

    it do
      is_included_in_links(
        tags_or_links,
        document_type: 'travel_advice',
        email_document_supertype: 'publications',
        government_document_supertype: 'news_stories',
      )
    end

    it do
      is_excluded_from_links(
        tags_or_links,
        document_type: 'other',
        email_document_supertype: 'publications',
        government_document_supertype: 'news_stories',
      )
    end

    it do
      is_excluded_from_links(
        tags_or_links,
        document_type: 'travel_advice',
        email_document_supertype: 'other',
        government_document_supertype: 'news_stories',
      )
    end

    it do
      is_excluded_from_links(
        tags_or_links,
        document_type: 'travel_advice',
        email_document_supertype: 'publications',
        government_document_supertype: 'other',
      )
    end
  end

  context 'when matching has tags fields' do
    it_behaves_like "#links matching", tags: { policies: { any: %w[eggs] } }, links: {}

    it "excluded when non-matching tags" do
      subscriber_list = create_subscriber_list(tags: { policies: { any: %w[apples] } })
      expect(subject.lists).not_to include(subscriber_list)
    end
  end

  context 'when matching has links fields' do
    it_behaves_like "#links matching", links: { policies: { any: %w[11aa] },
                                                taxon_tree: { all: %w[taxon2] } },
                                       tags: {}

    it "excluded when non-matching links" do
      subscriber_list = create_subscriber_list(links: { policies: { any: %w[aa11] },
                                                        taxon_tree: { all: %w[taxon1 taxon2] } })
      expect(subject.lists).not_to include(subscriber_list)
    end
  end

  context 'when matching neither links or tags fields' do
    it_behaves_like "#links matching", links: {}, tags: {}
  end

  context 'when a content_purpose_supergroup is provided' do
    let(:query_params) {
      {
        document_type: 'travel_advice',
        tags: { content_purpose_supergroup: 'guidance_and_regulation' }
      }
    }

    it "includes subscriber lists where the content_purpose_supergroup is set to the desired value" do
      list_params = { document_type: 'travel_advice', tags: { content_purpose_supergroup: { any: %w[guidance_and_regulation] } } }
      subscriber_list = create(:subscriber_list, defaults.merge(list_params))
      query = described_class.new(defaults.merge(query_params))
      expect(query.lists).to include(subscriber_list)
    end

    it "includes subscriber lists even if the content_purpose_supergroup is nil, if the document_type is the same value" do
      list_params = { document_type: 'travel_advice' }
      subscriber_list = create(:subscriber_list, defaults.merge(list_params))
      query = described_class.new(defaults.merge(query_params))
      expect(query.lists).to include(subscriber_list)
    end

    it "includes subscriber lists where the content_purpose_supergroup is set to the same value" do
      list_params = { tags: { content_purpose_supergroup: { any: %w[guidance_and_regulation] } } }
      subscriber_list = create(:subscriber_list, defaults.merge(list_params))
      query = described_class.new(defaults.merge(query_params))
      expect(query.lists).to include(subscriber_list)
    end

    it "excludes subscriber lists where the content_purpose_supergroup is set to a different value" do
      list_params = { document_type: 'travel_advice', tags: { content_purpose_supergroup: { any: %w[news_and_communications] } } }
      subscriber_list = create(:subscriber_list, defaults.merge(list_params))
      query = described_class.new(defaults.merge(query_params))
      expect(query.lists).not_to include(subscriber_list)
    end

    it "excludes subscriber lists where the content_purpose_supergroup is set to the same value but the document type is different" do
      list_params = { tags: { content_purpose_supergroup: { any: %w[guidance_and_regulation] } }, document_type: 'edition' }
      subscriber_list = create(:subscriber_list, defaults.merge(list_params))
      query = described_class.new(defaults.merge(query_params))
      expect(query.lists).not_to include(subscriber_list)
    end
  end

  context 'when a content_purpose_subgroup is provided' do
    query_params = { tags: { content_purpose_subgroup: %w[updates_and_alerts] } }
    list_params = { tags: { content_purpose_subgroup: { any: %w[updates_and_alerts] } } }

    it "includes subscriber lists where the content_purpose_subgroup is set to the desired value" do
      subscriber_list = create(:subscriber_list, defaults.merge(list_params))
      query = described_class.new(defaults.merge(query_params))
      expect(query.lists).to include(subscriber_list)
    end

    it "excludes subscriber lists where the content_purpose_subgroup is set to a different value" do
      list_params = { tags: { content_purpose_subgroup: { any: %w[speeches_and_statements] } } }
      subscriber_list = create(:subscriber_list, defaults.merge(list_params))
      query = described_class.new(defaults.merge(query_params))
      expect(query.lists).not_to include(subscriber_list)
    end
  end

  def create_subscriber_list(options)
    create(:subscriber_list, options)
  end

  def defaults
    {
      links: {},
      tags: {},
      document_type: '',
      email_document_supertype: '',
      government_document_supertype: '',
    }
  end

  def is_included_in_links(links_or_tags, criteria)
    subscriber_list = create(:subscriber_list, defaults.merge(links_or_tags).merge(criteria))
    expect(subject.lists).to include(subscriber_list)
  end

  def is_excluded_from_links(links_or_tags, criteria)
    subscriber_list = create(:subscriber_list, defaults.merge(links_or_tags).merge(criteria))
    expect(subject.lists).not_to include(subscriber_list)
  end
end
