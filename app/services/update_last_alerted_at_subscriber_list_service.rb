class UpdateLastAlertedAtSubscriberListService
  include Callable

  def initialize(content_change)
    @content_change = content_change
  end

  def call
    subscriber_list_ids = MatchedContentChange.where(content_change_id: content_change.id).pluck(:subscriber_list_id)
    SubscriberList.where(id: subscriber_list_ids).update_all(last_alerted_at: Time.zone.now)
  end

private

  attr_reader :content_change
end
