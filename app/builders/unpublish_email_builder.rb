class UnpublishEmailBuilder
  def self.call(*args)
    new.call(*args)
  end

  def call(emails, redirect)
    ids = Email.import!(email_records(emails, redirect)).ids
    Email.where(id: ids)
  end

private

  def email_records(emails, redirect)
    emails.map do |email|
      {
        address: email.fetch(:address),
        subject: email.fetch(:subject),
        body: body(email.fetch(:subject), email.fetch(:address), redirect),
        subscriber_id: email.fetch(:subscriber_id)
      }
    end
  end

  def body(title, address, _)
    <<~BODY
      You were subscribed to emails about '#{title}'. This topic no longer exists so you won't get any more emails about it.

      #{presented_manage_subscriptions_links(address)}
    BODY
  end

  def presented_manage_subscriptions_links(address)
    ManageSubscriptionsLinkPresenter.call(address: address)
  end
end
