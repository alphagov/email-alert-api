class BulkEmailBodyPresenter < ApplicationPresenter
  def initialize(body, subscriber_list)
    @body = body
    @subscriber_list = subscriber_list
  end

  def call
    body.gsub("%LISTURL%", PublicUrls.url_for(base_path: subscriber_list.url.to_s))
  end

private

  attr_reader :body, :subscriber_list
end
