class UnsubscribeLinkPresenter
  def self.call(id:, title:)
    url = PublicUrlService.url_for(base_path: "/email/unsubscribe/#{id}")
    "Unsubscribe from [#{title}](#{url})"
  end
end
