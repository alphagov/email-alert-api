class EmailArchiveQuery
  def self.call
    new.call
  end

  def call
    Email.where(archived_at: nil).select(fields)
  end

  private_class_method :new

private

  def fields
    [
      :created_at,
      content_change_ids,
      digest_run_ids,
      message_ids,
      :id,
      :subject,
      :subscriber_id,
      subscription_ids,
    ]
  end

  def subscription_ids
    query = SubscriptionContent
      .where("email_id = emails.id")
      .distinct
      .select(:subscription_id)
    "ARRAY(#{query.to_sql}) AS subscription_ids"
  end

  def content_change_ids
    query = SubscriptionContent
      .where("email_id = emails.id")
      .where.not(content_change_id: nil)
      .distinct
      .select(:content_change_id)
    "ARRAY(#{query.to_sql}) AS content_change_ids"
  end

  def message_ids
    query = SubscriptionContent
      .where("email_id = emails.id")
      .where.not(message_id: nil)
      .distinct
      .select(:message_id)
    "ARRAY(#{query.to_sql}) AS message_ids"
  end

  def digest_run_ids
    query = SubscriptionContent
      .joins(:digest_run_subscriber)
      .where("email_id = emails.id")
      .distinct
      .select("digest_run_subscribers.digest_run_id")
    "ARRAY(#{query.to_sql}) AS digest_run_ids"
  end
end
