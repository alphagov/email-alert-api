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
        body: body(email.fetch(:subject), email.fetch(:address), email.fetch(:redirect), email.fetch(:utm_parameters)),
        subscriber_id: email.fetch(:subscriber_id)
      }
    end
  end

  def body(title, address, redirect, utm_parameters)
    <<~BODY
      Your subscription to email updates about '#{title}' has ended because this topic no longer exists on GOV.UK.

      You might want to subscribe to updates about '#{redirect.title}' instead: #{add_query_params(redirect.url, utm_parameters)}

      #{presented_manage_subscriptions_links(address)}
    BODY
  end

  def add_query_params(redirect_url, query_params)
    uri = URI.parse(redirect_url)
    uri.query = [uri.query, *query_params.map { |k| k.join('=') }].compact.join('&')
    uri.to_s
  end

  def presented_manage_subscriptions_links(address)
    ManageSubscriptionsLinkPresenter.call(address: address)
  end
end
