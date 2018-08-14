class UnpublishEmailBuilder
  def self.call(*args)
    new.call(*args)
  end

  def call(emails)
    ids = Email.import!(email_records(emails)).ids
    Email.where(id: ids)
  end

private

  def email_records(emails)
    emails.map do |email|
      {
        address: email.fetch(:address),
        subject: email.fetch(:subject),
        body: body(email.fetch(:subject), email.fetch(:address)),
        subscriber_id: email.fetch(:subscriber_id)
      }
    end
  end

  def body(title, address)
    <<~BODY
      Your subscription to ‘#{title}’ no longer exists, as a result you will no longer receive emails
      about this subject.

      #{presented_manage_subscriptions_links(address)}

      &nbsp;

      ^Is this email useful? [Answer some questions to tell us more](https://www.smartsurvey.co.uk/s/govuk-email/?f=immediate).
    BODY
  end

  def presented_manage_subscriptions_links(address)
    ManageSubscriptionsLinkPresenter.call(address: address)
  end
end
