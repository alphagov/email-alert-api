class Reports::SubscriberListSubscriberCountReport
  class BadDateError < StandardError; end

  attr_reader :url, :active_on_date

  def initialize(url, active_on_date = nil)
    @url = url
    @active_on_date = active_on_date || Time.zone.now.end_of_day
  end

  def call
    list = SubscriberList.find_by_url(url)
    if list
      count = list.subscriptions
          .active_on(formatted_date)
          .count

      "Subscriber list for #{url} had #{count} subscribers on #{formatted_date}."
    else
      "Subscriber list cannot be found with URL: #{url}"
    end
  rescue ArgumentError
    "Cannot parse active_on_date, is this a valid ISO8601 date?: #{active_on_date}"
  end

private

  def formatted_date
    return active_on_date if active_on_date.instance_of?(ActiveSupport::TimeWithZone)

    Time.zone.strptime(active_on_date, "%F").end_of_day
  end
end
