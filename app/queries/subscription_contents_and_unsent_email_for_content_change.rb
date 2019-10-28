class SubscriptionContentsAndUnsentEmailForContentChange
  def self.call(content_change_id)
    SubscriptionContent.
      includes(:email).
      where(content_change_id: content_change_id).
      where.not(emails: { status: "sent" })
  end
end
