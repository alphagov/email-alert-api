class ContentItem
  DEFAULT = ''.freeze
  attr_reader :path

  class RedirectDetected < StandardError
  end

  def initialize(path)
    @path = path
  end

  def title
    @title ||= begin
      content_store_data['title'] || DEFAULT
    rescue GdsApi::HTTPNotFound
      DEFAULT
    end
  end

  def content_id
    content_store_data.to_h['content_id']
  end

  def url
    @url ||= PublicUrlService.absolute_url(path: @path)
  end

  def content_store_data
    @content_store_data ||= begin
      response = Services.content_store.content_item(@path).to_h

      unless response['base_path'] == @path
        raise RedirectDetected.new(
          "requested '#{@path}' got '#{response['base_path']}'"
        )
      end

      response
    end
  end
end
