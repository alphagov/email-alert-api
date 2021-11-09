class BulkSubscriberListEmailBuilderWithAccount < BulkSubscriberListEmailBuilder
  def filter_subscriptions(subscriptions)
    subscriptions.select { |sub| Services.accounts_emails.include?(sub.subscriber.address) }
  end
end
