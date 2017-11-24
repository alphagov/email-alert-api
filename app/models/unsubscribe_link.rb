class UnsubscribeLink
  attr_reader :url, :title
  def initialize(subscription)
    @subscription = subscription
    @title = subscription.subscriber_list.title
    @url = build_url
  end

  def self.for(subscriptions)
    Array(subscriptions).map do |subscription|
      new(subscription)
    end
  end

private

  attr_reader :subscription

  def build_url
    root = Plek.new.website_root
    escaped_title = URI.encode(title, /\W/)
    "#{root}/email/unsubscribe/#{subscription.uuid}?title=#{escaped_title}"
  end
end
