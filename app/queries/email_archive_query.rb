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
      :created_at,
      content_change_ids,
      digest_run_ids,
      :finished_sending_at,
      :id,
      :marked_as_spam,
      sent,
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
    "CASE\
      WHEN status=#{Email.statuses['sent']}\
      THEN true\
      ELSE false\
    END AS sent"
  end
end
