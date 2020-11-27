class Reports::SubscriberListsReport
  attr_reader :date, :slugs, :tags_pattern

  CSV_HEADERS = %i[title
                   slug
                   matching_criteria
                   created_at
                   individual_subscribers
                   daily_subscribers
                   weekly_subscribers
                   unsubscriptions
                   matched_content_changes_for_date
                   matched_messages_for_date].freeze

  def initialize(date, slugs: "", tags_pattern: nil)
    @date = Time.zone.parse(date)
    @slugs = slugs.split(",")
    @tags_pattern = tags_pattern
  end

  def call
    validate_date
    validate_slugs

    CSV.generate do |csv|
      csv << CSV_HEADERS
      lists_to_report.find_each { |list| csv << export_list_row(list) }
    end
  end

private

  def lists_to_report
    scope = SubscriberList.where("created_at < ?", date.end_of_day)
    scope = scope.where(slug: slugs) if slugs.any?
    scope = scope.where("tags::text like ?", "%#{tags_pattern}%") if tags_pattern
    scope
  end

  def validate_date
    raise "Invalid date" if date.blank?
    raise "Date must be in the past" if date >= Time.zone.today
    raise "Date must be within a year old" if date <= 1.year.ago
  end

  def validate_slugs
    not_found = slugs - lists_to_report.pluck(:slug)
    raise "Lists not found for slugs: #{not_found.join(',')}" if not_found.any?
  end

  def export_list_row(list)
    unsubscriptions_count = list.subscriptions.where("ended_at <= ?", date.end_of_day).count
    scope = list.subscriptions.active_on(date.end_of_day)

    [list.title,
     list.slug,
     criteria(list),
     list.created_at,
     scope.immediately.count,
     scope.daily.count,
     scope.weekly.count,
     unsubscriptions_count,
     matched_content_changes_count(list),
     matched_messages_count(list)]
  end

  def criteria(list)
    list.as_json(root: false,
                 only: %i[links
                          tags
                          email_document_supertype
                          government_document_supertype
                          document_type]).to_json
  end

  def matched_content_changes_count(list)
    MatchedContentChange
      .where(subscriber_list: list)
      .where("created_at > ? AND created_at <= ?", date.beginning_of_day, date.end_of_day)
      .count
  end

  def matched_messages_count(list)
    MatchedMessage
      .where(subscriber_list: list)
      .where("created_at > ? AND created_at <= ?", date.beginning_of_day, date.end_of_day)
      .count
  end
end
