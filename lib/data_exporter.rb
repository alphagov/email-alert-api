class DataExporter
  def present_subscriber_list(list_id)
    list = SubscriberList.find(list_id)
    { subscriber_list_id: list_id, title: list.title, count: list.subscribers.count }
  rescue ActiveRecord::RecordNotFound
    warn "could not fetch record for #{list_id}"
  end

  def export_csv(list_ids)
    CSV($stdout, headers: %i[subscriber_list_id title count], write_headers: true) do |csv|
      rows = list_ids.map { |list_id| present_subscriber_list(list_id) }
      rows.compact.each { |row| csv << row }
    end
  end
end
