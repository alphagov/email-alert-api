class MatchedContentChangeGenerationService
  include Callable

  def initialize(content_change)
    @content_change = content_change
  end

  def call
    # if we have records already, then we expect the process completed
    # successfully previously since the insert is an atomic operation
    return if MatchedContentChange.exists?(content_change:) || subscriber_lists.empty?

    now = Time.zone.now
    records = subscriber_lists.map do |list|
      {
        content_change_id: content_change.id,
        subscriber_list_id: list.id,
        created_at: now,
        updated_at: now,
      }
    end

    MatchedContentChange.insert_all!(records)
  end

private

  attr_reader :content_change

  def subscriber_lists
    @subscriber_lists ||= SubscriberListQuery.new(
      content_id: content_change.content_id,
      tags: content_change.tags,
      links: content_change.links,
      document_type: content_change.document_type,
      email_document_supertype: content_change.email_document_supertype,
      government_document_supertype: content_change.government_document_supertype,
    ).lists
  end
end
