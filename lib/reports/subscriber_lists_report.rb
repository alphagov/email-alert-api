class Reports::SubscriberListsReport
  attr_reader :date, :slugs, :tags_pattern, :links_pattern, :headers

  def initialize(date, slugs: "", tags_pattern: nil, links_pattern: nil, headers: nil)
    @date = Date.parse(date)
    @slugs = slugs.split(",")
    @tags_pattern = tags_pattern
    @links_pattern = links_pattern
    @headers = parse_headers(headers)
  end

  def call
    validate_date
    validate_slugs
    validate_headers

    CSV.generate do |csv|
      csv << headers
      lists_to_report.find_each { |list| csv << Reports::SubscriberListsReportRow.new(date, headers, list).call }
    end
  end

private

  def lists_to_report
    scope = SubscriberList.where("created_at < ?", date.end_of_day)
    scope = scope.where(slug: slugs) if slugs.any?
    scope = scope.where("tags::text like ?", "%#{tags_pattern}%") if tags_pattern
    scope = scope.where("links::text like ?", "%#{links_pattern}%") if links_pattern
    scope
  end

  def validate_date
    raise "Date must be in the past" if date >= Time.zone.today
    raise "Date must be within a year old" if date <= 1.year.ago
  end

  def validate_slugs
    not_found = slugs - lists_to_report.pluck(:slug)
    raise "Lists not found for slugs: #{not_found.join(',')}" if not_found.any?
  end

  def validate_headers
    not_found = headers - default_headers
    raise "Header is not a valid option: #{not_found.join(', ')}" if not_found.any?
  end

  def parse_headers(headers)
    return default_headers unless headers

    headers.split(",").map(&:strip).map(&:to_sym)
  end

  def default_headers
    %i[title
       slug
       url
       matching_criteria
       created_at
       individual_subscribers
       daily_subscribers
       weekly_subscribers
       unsubscriptions
       matched_content_changes_for_date
       matched_messages_for_date
       total_subscribers].freeze
  end
end
