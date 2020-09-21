require "csv"

class Reports::BrexitSubscribersReport
  CSV_HEADERS = %w[title slug tags subscribed unsubscribed immediately daily weekly].freeze
  attr_reader :date

  def initialize(date = nil)
    @date = date
  end

  def self.call(*args)
    new(args).call
  end

  def call
    subscriber_lists =
      date.empty? ? brexit_lists : brexit_lists_before_date
    CSV.instance($stdout, headers: CSV_HEADERS, write_headers: true) do |csv|
      subscriber_lists.each do |list|
        csv << row_data(list)
      end
    end
  end

private

  def parsed_date
    unless date.empty?
      @parsed_date ||= Date.parse(date.to_s)
    end
  end

  def brexit_lists
    @brexit_lists ||= SubscriberList.where("subscriber_lists.tags->>'brexit_checklist_criteria' IS NOT NULL")
  end

  def brexit_lists_before_date
    brexit_lists.select { |list| subscribed_to_before_date(list) }
  end

  def subscribed_to_before_date(list)
    subscriptions =
      list.subscribers.select do |subscriber|
        subscriber.created_at <= parsed_date
      end
    subscriptions.any?
  end

  def row_data(list)
    active = list.subscriptions.active
    inactive = list.subscriptions.ended
    [list.title, list.slug, list.tags, active.count, inactive.count, active.immediately.count, active.daily.count, active.weekly.count]
  end
end
