SubscriberList = Struct.new(
  :id,
  :title,
  :subscription_url,
  :gov_delivery_id,
  :created_at,
  :tags,
) do
  def to_json(*args, &block)
    to_h
      .merge(
        :created_at => created_at.iso8601,
      )
      .to_json(*args, &block)
  end
end
