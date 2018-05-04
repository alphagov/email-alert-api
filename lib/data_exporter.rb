class DataExporter
  CSV_HEADERS = %i(id title count).freeze

  EU_COUNTRIES = %w(
    austria belgium bulgaria croatia cyprus czech-republic denmark estonia finland france germany greece hungary
    ireland italy latvia lithuania luxembourg malta netherlands poland portugal slovakia slovenia spain sweeden
  ).freeze

  def living_in_eu_subscriber_lists
    slugs = EU_COUNTRIES.map { |country| "living-in-#{country}" }
    SubscriberList.where(slug: slugs)
  end

  def present_subscriber_list(subscriber_list)
    {
      id: subscriber_list.id,
      title: subscriber_list.title,
      count: subscriber_list.active_subscriptions_count,
    }
  end

  def export_csv(subscriber_lists)
    CSV($stdout, headers: CSV_HEADERS, write_headers: true) do |csv|
      subscriber_lists.find_each do |subscriber_list|
        csv << present_subscriber_list(subscriber_list)
      end
    end
  end

  def export_csv_from_ids(ids)
    export_csv(SubscriberList.where(id: ids))
  end

  def export_csv_from_living_in_eu
    export_csv(living_in_eu_subscriber_lists)
  end
end
