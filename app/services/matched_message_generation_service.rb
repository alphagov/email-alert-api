class MatchedMessageGenerationService
  include Callable

  def initialize(message)
    @message = message
  end

  def call
    # if we already have records already, then we expect the process completed
    # successfully previously since the insert is an atomic operation
    return if MatchedMessage.exists?(message:) || subscriber_lists.empty?

    now = Time.zone.now
    records = subscriber_lists.map do |list|
      {
        message_id: message.id,
        subscriber_list_id: list.id,
        created_at: now,
        updated_at: now,
      }
    end

    MatchedMessage.insert_all!(records)
  end

private

  attr_reader :message

  def subscriber_lists
    @subscriber_lists ||= SubscriberList.matching_criteria_rules(message.criteria_rules)
  end
end
