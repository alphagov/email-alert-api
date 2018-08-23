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

  def body(title, address, redirect)
    <<~BODY
      Your subscription to email updates about '#{title}' has ended because this topic no longer exists on GOV.UK.

      You might want to subscribe to updates about '#{redirect.title}' instead: #{redirect.url}

      #{presented_manage_subscriptions_links(address)}
    BODY
  end

  def presented_manage_subscriptions_links(address)
    ManageSubscriptionsLinkPresenter.call(address: address)
  end
end
