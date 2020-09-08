class Reports::MatchedContentChangesReport
  OUTPUT_ATTRIBUTES = {
    created_at: :content_change,
    base_path: :content_change,
    change_note: :content_change,
    document_type: :content_change,
    publishing_app: :content_change,
    priority: :content_change,
    title: :subscriber_list,
    slug: :subscriber_list,
  }.freeze

  def call(start_time: nil, end_time: nil)
    start_time = start_time ? Time.zone.parse(start_time) : 1.week.ago
    end_time = end_time ? Time.zone.parse(end_time) : Time.zone.now

    query = MatchedContentChange
      .includes(:subscriber_list, :content_change) # for efficient "row.content_change"
      .joins(:content_change) # for the next query
      .where("content_changes.created_at": start_time..end_time)
      .order("matched_content_changes.created_at desc")

    CSV.generate do |csv|
      csv << OUTPUT_ATTRIBUTES.keys

      query.each do |row|
        csv << OUTPUT_ATTRIBUTES.map do |sub_field, field|
          row.public_send(field).public_send(sub_field)
        end
      end
    end
  end
end
