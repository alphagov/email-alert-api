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
    return "" unless subscriber_list.url

    PublicUrls.url_for(
      base_path: subscriber_list.url,
      utm_source: subscriber_list.slug,
      utm_campaign: "govuk-notifications-bulk",
      utm_medium: "email",
    )
  end
end
