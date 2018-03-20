class EmailArchiveQuery
  def self.call
    new.call
  end

  def call
    Email.archivable.select(fields)
  end

  private_class_method :new

private

  def fields
    [
      :id,
      :subject,
      :finished_sending_at,
      :created_at,
      :subscriber_id,
      subscription_ids,
      content_change_ids,
      digest_run_ids,
      sent,
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
      .distinct
      .select(:content_change_id)
    "ARRAY(#{query.to_sql}) AS content_change_ids"
  end

  def digest_run_ids
    query = SubscriptionContent
      .joins(:digest_run_subscriber)
      .where("email_id = emails.id")
      .distinct
      .select("digest_run_subscribers.digest_run_id")
    "ARRAY(#{query.to_sql}) AS digest_run_ids"
  end

  def sent
    query = DeliveryAttempt
      .where(status: :delivered)
      .where("email_id = emails.id")
    "EXISTS(#{query.to_sql}) AS sent"
  end
end
