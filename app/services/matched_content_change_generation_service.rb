class MatchedContentChangeGenerationService
  def initialize(content_change:)
    @content_change = content_change
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    MatchedContentChange.import!(records)
  end

private

  attr_reader :content_change

  def records
    subscriber_lists.map do |subscriber_list|
      {
        content_change_id: content_change.id,
        subscriber_list_id: subscriber_list.id,
      }
    end
  end

  def subscriber_lists
    SubscriberListQuery.new(
      tags: content_change.tags,
      links: content_change.links,
      document_type: content_change.document_type,
      email_document_supertype: content_change.email_document_supertype,
      government_document_supertype: content_change.government_document_supertype,
    ).lists
  end
end
