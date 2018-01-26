class UnsubscribeLinkPresenter
  def initialize(uuid:, title:)
    @uuid = uuid
    @title = title
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    "Unsubscribe from [#{title}](#{url})"
  end

private

  attr_reader :uuid, :title

  def url
    escaped_title = ERB::Util.url_encode(title)
    base_path = "/email/unsubscribe/#{uuid}?title=#{escaped_title}"
    PublicUrlService.url_for(base_path: base_path)
  end
end
