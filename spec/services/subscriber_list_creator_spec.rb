require "rails_helper"

RSpec.describe SubscriberListCreator do
  context "when gov delivery ID is not passed in" do
    let(:params) do
      {
        title: "This is a short title",
        enabled: true,
        tags: {},
        links: {},
        migrated_from_gov_uk_delivery: false,
        document_type: 'news-article',
        email_document_supertype: 'publications',
        government_document_supertype: 'news-articles',
      }
    end

    before do
      allow(Services.gov_delivery).to receive(:create_topic).and_return('TOPIC_123')
    end

    it "creates a subscriber list with title, containing the record ID" do
      creator = described_class.new(params)
      creator.save
      expect(creator.record).to have_attributes(
        title: "This is a short title (#{creator.record.id})",
        enabled: true,
        tags: {},
        links: {},
        migrated_from_gov_uk_delivery: false,
        document_type: 'news-article',
        email_document_supertype: 'publications',
        government_document_supertype: 'news-articles',
        gov_delivery_id: 'TOPIC_123',
      )
    end

    it "creates the topic on gov_delivery" do
      creator = described_class.new(params)
      creator.save
      expect(Services.gov_delivery).to have_received(:create_topic)
        .with("This is a short title (#{creator.record.id})")
    end

    context "and the title is longer than 255 characters" do
      it "trims the title" do
        title = 'ABCDEFGHIJ' * 26
        creator = described_class.new(params.merge(title: title))
        creator.save

        title = "#{title[0..(254 - " (#{creator.record.id})".size)]} (#{creator.record.id})"
        expect(creator.record).to have_attributes(title: title)
      end
    end
  end

  context "when gov delivery ID is passed in" do
    let(:params) do
      {
        title: "This is a short title",
        enabled: true,
        tags: {},
        links: {},
        migrated_from_gov_uk_delivery: false,
        document_type: 'news-article',
        email_document_supertype: 'publications',
        government_document_supertype: 'news-articles',
        gov_delivery_id: 'TOPIC_ABC',
      }
    end

    it "creates a subscriber list with the provided title" do
      creator = described_class.new(params)
      creator.save
      expect(creator.record).to have_attributes(
        title: "This is a short title",
        enabled: true,
        tags: {},
        links: {},
        migrated_from_gov_uk_delivery: false,
        document_type: 'news-article',
        email_document_supertype: 'publications',
        government_document_supertype: 'news-articles',
        gov_delivery_id: 'TOPIC_ABC',
      )
    end

    it "does not create a topic on gov_delivery" do
      expect(Services.gov_delivery).not_to receive(:create_topic)
      creator = described_class.new(params)
      creator.save
    end
  end

end
