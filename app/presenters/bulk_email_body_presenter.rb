class BulkEmailBodyPresenter < ApplicationPresenter
  def initialize(body, subscriber_list)
    @body = body
    @subscriber_list = subscriber_list
  end

  def call
    body.gsub("%LISTURL%", list_url)
  end

private

  attr_reader :body, :subscriber_list

  def list_url
    tracking_params = [
      "utm_source=#{subscriber_list.slug}",
      "utm_medium=email",
      "utm_campaign=govuk-notifications-bulk",
    ]

    uri = URI.parse(subscriber_list.url)
    uri.query = ([uri.query] + tracking_params).compact.join("&")
    PublicUrls.url_for(base_path: uri.to_s)
  rescue URI::InvalidURIError
    ""
  end
end
