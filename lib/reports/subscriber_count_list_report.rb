require "csv"

class Reports::SubscriberCountListReport
  class BadDateError < StandardError; end

  attr_reader :url, :start_date, :end_date

  def initialize(url, start_date = nil, end_date = nil)
    @url = url
    @start_date = start_date || Time.zone.now.beginning_of_month
    @end_date = end_date || Time.zone.now.end_of_day
  end

  def call
    list = SubscriberList.find_by_url(url)
    return "Subscriber list cannot be found with URL: #{url}" unless list

    results = {}
    current_date = formatted_date(start_date).beginning_of_month
    end_date_formatted = formatted_date(end_date).end_of_month

    while current_date <= end_date_formatted
      count = list.subscriptions.active_on(current_date.end_of_day).count
      results[current_date.strftime("%d-%m-%Y")] = count
      current_date = current_date.next_month
    end

    CSV.generate do |csv|
      csv << %w[Date Count]
      results.each { |date, count| csv << [date, count] }
    end
  rescue ArgumentError
    "Cannot parse dates, are these valid ISO8601 dates?: start_date=#{start_date}, end_date=#{end_date}"
  end

private

  def formatted_date(date)
    return date if date.instance_of?(ActiveSupport::TimeWithZone)

    Time.zone.strptime(date, "%F")
  end
end
