require 'csv'

class Reports::ContentChangesInformation
  attr_reader :start_date, :end_date

  def initialize(start_date, end_date)
    @start_date = parse_date(start_date.to_s)
    @end_date = parse_date(end_date.to_s)
  end

  def report
    path = "#{Rails.root}/tmp/content_changes_time_#{start_date}_to_#{end_date}.csv".delete(' ')
    headers = %w[content_change_id
                 content_change_base_path
                 created_at
                 emails_sent
                 subscriber_list_titles]

    puts "CSV is being generated for content_changes between #{start_date} - #{end_date}"
    puts "The information being returned includes content_change_id, content_change_base_path, created_at, emails_sent, subscriber_list_titles"

    CSV.open(path, 'wb', headers: headers, write_headers: true) do |csv|
      email_data.each do |data|
        csv << data
      end
    end

    puts "The CSV file is available at - #{path}"
  end

private

  def parse_date(date)
    raise ArgumentError, 'Date(s) entered need to be of date/time format' unless Time.zone.parse(date)

    Time.zone.parse(date)
  end

  def content_changes
    ContentChange
      .where(created_at: DateTime.now.beginning_of_day..DateTime.now.end_of_day)
      .where.not(processed_at: nil)
      .pluck(:id)
  end

  def email_data
    data = SubscriptionContent
      .joins(:content_change)
      .joins(:email)
      .joins(subscription: :subscriber_list)
      .where(emails: { status: :sent })
      .where(content_change: content_changes)
      .group(:content_change_id, "content_changes.created_at", "content_changes.base_path")
      .pluck(:content_change_id,
             "content_changes.base_path",
             "content_changes.created_at",
             "COUNT(subscription_contents.email_id)",
             "ARRAY_AGG(subscriber_lists.title)")

    data.map { |x| [x[0], x[1], x[2].to_s, x[3].to_s, x[4].join(', ')] }
  end
end
