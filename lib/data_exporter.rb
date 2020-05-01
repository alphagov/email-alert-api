require "csv"

class DataExporter
  def export_csv_from_ids(ids)
    export_csv(SubscriberList.where(id: ids))
  end

  def export_csv_from_ids_at(date, ids)
    export_csv(SubscriberList.where(id: ids), at: date)
  end

  def export_csv_from_slugs(slugs)
    export_csv(SubscriberList.where(slug: slugs))
  end

  def export_csv_from_slugs_at(date, slugs)
    export_csv(SubscriberList.where(slug: slugs), at: date)
  end

  def export_csv_from_living_in_europe
    export_csv(living_in_europe_subscriber_lists)
  end

  def export_csv_from_travel_advice_at(date)
    travel_advice_csv(travel_advice_subscriber_lists, at: date)
  end

private

  CSV_HEADERS = %i[id title count].freeze

  EUROPEAN_COUNTRIES = %w[
    austria belgium bulgaria croatia cyprus czech-republic denmark estonia finland france germany greece hungary
    ireland italy latvia lithuania luxembourg malta netherlands poland portugal slovakia slovenia spain sweden
    switzerland iceland norway liechtenstein
  ].freeze

  def living_in_europe_subscriber_lists
    slugs = EUROPEAN_COUNTRIES.map { |country| "living-in-#{country}" }
    SubscriberList.where(slug: slugs)
  end

  def subscriber_list_count(subscriber_list, date)
    return subscriber_list.active_subscriptions_count unless date

    subscriber_list
      .subscriptions
      .where("created_at < ?", date)
      .where("ended_at IS NULL OR ended_at >= ?", date)
      .count
  end

  def present_subscriber_list(subscriber_list, at:)
    {
      id: subscriber_list.id,
      title: subscriber_list.title,
      count: subscriber_list_count(subscriber_list, at),
    }
  end

  def export_csv(subscriber_lists, at: nil)
    CSV($stdout, headers: CSV_HEADERS, write_headers: true) do |csv|
      subscriber_lists.find_each do |subscriber_list|
        csv << present_subscriber_list(subscriber_list, at: at)
      end
    end
  end

  def travel_advice_csv(subscriber_lists, at: nil)
    CSV($stdout, headers: %i[title subscribed unsubscribed immediately daily weekly], write_headers: true) do |csv|
      subscriber_lists.find_each do |subscriber_list|
        csv << present_travel_advice_report(subscriber_list, at: at)
      end
    end
  end

  def present_travel_advice_report(subscriber_list, at: nil)
    {
      title: cleanup(subscriber_list.title),
      subscribed: subscribed_during_week_ending_on(subscriber_list, at).count,
      unsubscribed: unsubscribed_during_week_ending_on(subscriber_list, at).count,
    }
      .merge(subscriber_list_frequency_count(subscriber_list, at))
  end

  def subscribed_during_week_ending_on(subscriber_list, date)
    subscriber_list.subscriptions.where(created_at: week_ending_on(date), source: :user_signed_up)
  end

  def unsubscribed_during_week_ending_on(subscriber_list, date)
    subscriber_list.subscriptions.where(ended_at: week_ending_on(date), ended_reason: :unsubscribed)
  end

  def week_ending_on(date)
    end_date   = Date.parse(date)
    start_date = end_date - 1.week
    start_date..end_date
  end

  def subscriber_list_frequency_count(subscriber_list, at)
    Subscription
      .where(subscriber_list: subscriber_list)
      .where("created_at < ?", at)
      .where("ended_at IS NULL OR ended_at >= ?", at)
      .group(:frequency)
      .count
      .symbolize_keys
  end

  def travel_advice_subscriber_lists
    SubscriberList.where("links->'countries' IS NOT NULL").or(SubscriberList.where(slug: "travel-advice-for-all-countries-travel-advice"))
  end

  def cleanup(title)
    title
      .gsub(",", "")
      .gsub("- travel advice", "")
      .strip
  end
end
