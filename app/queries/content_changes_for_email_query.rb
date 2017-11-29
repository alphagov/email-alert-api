class ContentChangesForEmailQuery
  def self.call(email)
    subscription_content = SubscriptionContent
      .where("subscription_contents.content_change_id = content_changes.id")
      .where(email: email)
      .exists
    ContentChange.where(subscription_content)
  end
end
