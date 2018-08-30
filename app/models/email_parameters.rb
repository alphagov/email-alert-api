class EmailParameters
  attr_reader :subject, :address, :redirect, :utm_parameters, :subscriber_id

  def initialize(subject:, address:, redirect:, utm_parameters:, subscriber_id:)
    @subject = subject
    @address = address
    @redirect = redirect
    @utm_parameters = utm_parameters
    @subscriber_id = subscriber_id
  end

  def fetch_binding
    binding
  end

  def add_utm(url)
    uri = URI.parse(url)
    uri.query = [uri.query, *utm_parameters.map { |k| k.join('=') }].compact.join('&')
    uri.to_s
  end

  def presented_manage_subscriptions_links(address)
    ManageSubscriptionsLinkPresenter.call(address: address)
  end
end
