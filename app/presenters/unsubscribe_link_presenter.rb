class UnsubscribeLinkPresenter
  def initialize(id:, title:)
    @id = id
    @title = title
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    "[Unsubscribe from ‛#{title}’](#{url})"
  end

  private_class_method :new

private

  attr_reader :id, :title

  def url
    escaped_title = ERB::Util.url_encode(title)
    base_path = "/email/unsubscribe/#{id}?title=#{escaped_title}"
    PublicUrlService.url_for(base_path: base_path)
  end
end
