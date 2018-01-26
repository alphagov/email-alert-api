class UnsubscribeLinkPresenter
  attr_reader :uuid, :title

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

  def url
    PublicUrlService.url_for(base_path: "/email/unsubscribe/#{uuid}?title=#{escaped_title}")
  end

  def escaped_title
    ERB::Util.url_encode(title)
  end
end
