require 'rails_helper'

RSpec.describe FindExactQuery do

  context "when links are in the query" do
    it "matched when subscriber list has the same links" do
      query = build_query(links: { policies: ['aa-11'] })
      subscriber_list = create_subscriber_list(links: { policies: ['aa-11'] })
      expect(query.exact_match).to eq(subscriber_list)
    end

    it "matched when subscriber list has the same links and matching document_type" do
      query = build_query(links: { policies: ['aa-11'] }, document_type: 'travel_advice')
      subscriber_list = create_subscriber_list(links: { policies: ['aa-11'] }, document_type: 'travel_advice')
      expect(query.exact_match).to eq(subscriber_list)
    end

    it "matched when subscriber list has the same links and matching email_document_supertype" do
      query = build_query(links: { policies: ['aa-11'] }, email_document_supertype: 'publications')
      subscriber_list = create_subscriber_list(links: { policies: ['aa-11'] }, email_document_supertype: 'publications')
      expect(query.exact_match).to eq(subscriber_list)
    end

    it "not matched when subscriber list has different links" do
      query = build_query(links: { policies: ['aa-11'] })
      subscriber_list = create_subscriber_list(links: { policies: ['11-aa'] })
      expect(query.exact_match).to be_nil
    end

    it "not matched when subscriber list has no links" do
      query = build_query(links: { policies: ['aa-11'] })
      subscriber_list = create_subscriber_list
      expect(query.exact_match).to be_nil
    end

    it "not matched on tags if unable to match links - even if it would match" do
      query = build_query(links: { policies: ['aa-11'] }, tags: { policies: ['apples'] })
      subscriber_list = create_subscriber_list(tags: { policies: ['apples'] })
      expect(query.exact_match).to be_nil
    end

    it "not matched on document type - even if they match" do
      query = build_query(links: { policies: ['aa-11'] }, document_type: 'travel_advice')
      subscriber_list = create_subscriber_list(document_type: 'travel_advice')
      expect(query.exact_match).to be_nil
    end
  end

  context "when tags are in the query" do
    it "matched when subscriber tags has the same tags" do
      query = build_query(tags: { policies: ['beer'] })
      subscriber_list = create_subscriber_list(tags: { policies: ['beer'] })
      expect(query.exact_match).to eq(subscriber_list)
    end

    it "matched when subscriber list has the same tags and matching document_type" do
      query = build_query(tags: { policies: ['beer'] }, document_type: 'document_type')
      subscriber_list = create_subscriber_list(tags: { policies: ['beer'] }, document_type: 'document_type')
      expect(query.exact_match).to eq(subscriber_list)
    end

    it "matched when subscriber list has the same tags and matching email_document_supertype" do
      query = build_query(tags: { policies: ['beer'] }, email_document_supertype: 'publications')
      subscriber_list = create_subscriber_list(tags: { policies: ['beer'] }, email_document_supertype: 'publications')
      expect(query.exact_match).to eq(subscriber_list)
    end

    it "not matched when subscriber list has different tags" do
      query = build_query(tags: { policies: ['beer'] })
      subscriber_list = create_subscriber_list(tags: { policies: ['cider'] })
      expect(query.exact_match).to be_nil
    end

    it "not matched when subscriber list has no tags" do
      query = build_query(tags: { policies: ['beer'] })
      subscriber_list = create_subscriber_list
      expect(query.exact_match).to be_nil
    end

    it "not matched on document type - even if they match" do
      query = build_query(tags: { policies: ['beer'] }, document_type: 'travel_advice')
      subscriber_list = create_subscriber_list(document_type: 'travel_advice')
      expect(query.exact_match).to be_nil
    end
  end

  it "matched on document type only" do
    query = build_query(document_type: 'travel_advice')
    subscriber_list = create_subscriber_list(document_type: 'travel_advice')
    expect(query.exact_match).to eq(subscriber_list)
  end

  it "not matched on different document type" do
    query = build_query(tags: { policies: ['beer'] }, document_type: 'travel_advice')
    subscriber_list = create_subscriber_list(document_type: 'other')
    expect(query.exact_match).to be_nil
  end

  it "matched on email document supertype only" do
    query = build_query(email_document_supertype: 'publications')
    subscriber_list = create_subscriber_list(email_document_supertype: 'publications')
    expect(query.exact_match).to eq(subscriber_list)
  end

  it "matched on email document supertype and government document supertype" do
    query = build_query(email_document_supertype: 'publications', government_document_supertype: 'news_stories')
    subscriber_list = create_subscriber_list(email_document_supertype: 'publications', government_document_supertype: 'news_stories')
    expect(query.exact_match).to eq(subscriber_list)
  end

  it "not matched when email document supertype matched and government document supertype not matched" do
    query = build_query(email_document_supertype: 'publications', government_document_supertype: 'news_stories')
    subscriber_list = create_subscriber_list(email_document_supertype: 'publications', government_document_supertype: 'other')
    expect(query.exact_match).to be_nil
  end

  it "not matched when subscriber list does have a gov_delivery_id" do
    query = build_query(email_document_supertype: 'publications')
    subscriber_list = create_subscriber_list(email_document_supertype: 'publications', gov_delivery_id: nil)
    expect(query.exact_match).not_to eq(subscriber_list)
  end

  it "not matched when subscriber list has a blank gov_delivery_id" do
    query = build_query(email_document_supertype: 'publications')
    subscriber_list = create_subscriber_list(email_document_supertype: 'publications', gov_delivery_id: '')
    expect(query.exact_match).not_to eq(subscriber_list)
  end

  def build_query(params={})
    defaults = {
      tags: {},
      links: {},
      document_type: '',
      email_document_supertype: '',
      government_document_supertype: '',
    }

    described_class.new(defaults.merge(params))
  end

  def create_subscriber_list(params={})
    defaults = {
      tags: {},
      links: {},
      document_type: '',
      email_document_supertype: '',
      government_document_supertype: '',
    }
    create(:subscriber_list, defaults.merge(params))
  end
end
