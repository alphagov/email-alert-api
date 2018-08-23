class ContentItem
  DEFAULT = ''.freeze
  attr_reader :path

  def initialize(path)
    @path = path
  end

  def title
    @title ||= begin
      Services.content_store.content_item(@path).to_h['title'] || DEFAULT
    rescue GdsApi::HTTPNotFound
      DEFAULT
    end
  end

  def url
    PublicUrlService.redirect_url(path: @path)
  end
end
