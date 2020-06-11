class Reports::MatchedContentChangesReport
  OUTPUT_ATTRIBUTES = {
    created_at: :content_change,
    base_path: :content_change,
    change_note: :content_change,
    document_type: :content_change,
    publishing_app: :content_change,
    priority: :content_change,
    title: :subscriber_list,
    subscription_count: :itself,
  }.freeze

  def call(start_time: nil, end_time: nil)
    start_time = start_time ? Time.zone.parse(start_time) : 1.week.ago
    end_time = end_time ? Time.zone.parse(end_time) : Time.zone.now

    subscription_count_query = Subscription
      .select("count(*)")
      .where("subscriptions.created_at <= content_changes.created_at")
      .where("subscriptions.ended_at is null or subscriptions.ended_at > content_changes.created_at")
      .where("subscriptions.subscriber_list_id = subscriber_lists.id")
      .where(frequency: "immediately")
      .arel
      .as("subscription_count")

    query = MatchedContentChange
      .select("*")
      .select(subscription_count_query)
      .includes(:subscriber_list, :content_change) # for efficient "row.content_change"
      .joins(:subscriber_list, :content_change) # for the nested query
      .where("content_changes.created_at": start_time..end_time)
      .order(subscription_count: :desc)

    CSV.generate do |csv|
      csv << OUTPUT_ATTRIBUTES.keys

      query.each do |row|
        next if row.subscription_count.zero?

        csv << OUTPUT_ATTRIBUTES.map do |sub_field, field|
          row.public_send(field).public_send(sub_field)
        end
      end
    end
  end
end
