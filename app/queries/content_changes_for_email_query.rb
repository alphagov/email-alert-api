class ContentChangesForEmailQuery
  def self.call(email)
    content_change_ids = SubscriptionContent
        .where(email: email)
        .select(:content_change_id)
    ContentChange.where(id: content_change_ids)
  end
end
