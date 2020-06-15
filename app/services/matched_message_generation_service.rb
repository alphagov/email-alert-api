class MatchedMessageGenerationService
  def initialize(message)
    @message = message
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    # if we already have any records already we expect the process completed
    # successfully previously since the insert is an atomic operation
    return if MatchedMessage.exists?(message: message)

    MatchedMessage.import!(columns, records)
  end

  private_class_method :new

private

  attr_reader :message

  def columns
    %i[message_id subscriber_list_id]
  end

  def records
    SubscriberList
      .matching_criteria_rules(message.criteria_rules)
      .map { |subscriber_list| [message.id, subscriber_list.id] }
  end
end
