class Reports::SubscriberListsReportRow
  def initialize(date, headers, list)
    @date = date
    @headers = headers
    @list = list
  end

  def call
    headers.map { |header| send(header) }
  end

private

  attr_reader :headers, :list, :date

  def title
    list.title
  end

  def slug
    list.slug
  end

  def url
    list.url
  end

  def matching_criteria
    list.as_json(root: false,
                 only: %i[links
                          tags
                          email_document_supertype
                          government_document_supertype
                          document_type]).to_json
  end

  def created_at
    list.created_at
  end

  def individual_subscribers
    scope.immediately.count
  end

  def daily_subscribers
    scope.daily.count
  end

  def weekly_subscribers
    scope.weekly.count
  end

  def total_subscribers
    scope.count
  end

  def unsubscriptions
    list.subscriptions.where(ended_reason: :unsubscribed)
      .where("ended_at <= ?", date.end_of_day).count
  end

  def matched_content_changes_for_date
    MatchedContentChange
      .where(subscriber_list: list)
      .where("created_at > ? AND created_at <= ?", date.beginning_of_day, date.end_of_day)
      .count
  end

  def matched_messages_for_date
    MatchedMessage
      .where(subscriber_list: list)
      .where("created_at > ? AND created_at <= ?", date.beginning_of_day, date.end_of_day)
      .count
  end

  def scope
    @scope ||= list.subscriptions.active_on(date.end_of_day)
  end
end
