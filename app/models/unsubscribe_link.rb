class UnsubscribeLink
  def self.for(subscriptions)
    subscriptions.includes(:subscriber_list).pluck(:title, :uuid).map do |title, uuid|
      new(title: title, uuid: uuid)
    end
  end

  attr_reader :title

  def initialize(title:, uuid:)
    @title = title
    @uuid = uuid
  end

  def url
    PublicUrlService.unsubscribe_url(uuid: uuid, title: title)
  end

private

  attr_reader :uuid
end
