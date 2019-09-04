class MatchedMessageGenerationService
  def initialize(message)
    @message = message
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    MatchedMessage.import!(columns, records)
  end

  private_class_method :new

private

  attr_reader :message

  def columns
    %i(message_id subscriber_list_id)
  end

  def records
    subscriber_lists.map { |subscriber_list| [message.id, subscriber_list.id] }
  end

  def subscriber_lists
    SubscriberListQuery.new(
      tags: message.tags,
      links: message.links,
      document_type: message.document_type,
      email_document_supertype: message.email_document_supertype,
      government_document_supertype: message.government_document_supertype
    ).lists
  end
end
