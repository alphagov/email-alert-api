class ContentChangeEmailStatusCount
  def initialize(content_change)
    @content_change = content_change
    @email_statuses = email_statuses
    @email_status_counts = email_status_counts
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    puts <<~TEXT
      -------------------------------------------
      Email status counts for Content Change #{@content_change.id}
      -------------------------------------------

      Sent emails: #{@email_status_counts[:sent]}

      Pending emails: #{@email_status_counts[:pending]}

      Failed emails: #{@email_status_counts[:failed]}

      -------------------------------------------
    TEXT
  end

private

  def email_statuses
    subscription_contents_ids = @content_change.subscription_contents.pluck(:id)
    email_ids = SubscriptionContent.where(id: subscription_contents_ids).pluck(:email_id)
    Email.where(id: email_ids).pluck(:status)
  end

  def email_status_counts
    {
      failed: status_count('failed'),
      sent: status_count('sent'),
      pending: status_count('pending')
    }
  end

  def status_count(status)
    @email_statuses.select { |email_status| email_status == status }.count
  end
end
