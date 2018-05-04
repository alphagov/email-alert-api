class DataExporter
  CSV_HEADERS = %i(id title count)

  def present_subscriber_list(subscriber_list)
    {
      id: subscriber_list.id,
      title: subscriber_list.title,
      count: subscriber_list.active_subscriptions_count,
    }
  end

  def export_csv(list_ids)
    CSV($stdout, headers: CSV_HEADERS, write_headers: true) do |csv|
      SubscriberList
        .where(id: list_ids)
        .find_each { |subscriber_list| csv << present_subscriber_list(subscriber_list) }
    end
  end
end
