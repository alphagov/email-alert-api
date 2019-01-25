class MatchedContentChangeGenerationService
  def initialize(content_change:)
    @content_change = content_change
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    MatchedContentChange.import!(columns, records)
  end

  private_class_method :new

private

  attr_reader :content_change

  def columns
    %i(content_change_id subscriber_list_id)
  end

  def records
    content_change_id = content_change.id
    subscriber_lists.map do |subscriber_list|
      [content_change_id, subscriber_list.id]
    end
  end

  def subscriber_lists
    SubscriberListQuery.new(
      tags: content_change.tags,
      links: content_change.links,
      document_type: content_change.document_type,
      email_document_supertype: content_change.email_document_supertype,
      government_document_supertype: content_change.government_document_supertype,
      content_purpose_supergroup: content_change.content_purpose_supergroup,
    ).lists
  end
end
