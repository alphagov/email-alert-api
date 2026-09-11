class Reports::SubscriberListBySlugSubscriberCountReport
  class BadDateError < StandardError; end

  attr_reader :slug

  def initialize(slug)
    @slug = slug
  end

  def call
    list = SubscriberList.find_by_slug(slug)
    date = Time.zone.now.end_of_day

    if list
      count = list.subscriptions
          .active_on(date)
          .count

      "Subscriber list for #{slug} had #{count} subscribers on #{date}."
    else
      raise "Subscriber list cannot be found with slug: #{slug}"
    end
  end
end
