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
   "#{root}/email/unsubscribe/#{subscription.uuid}#{title_param}"
  end

  def root
    Plek.new.website_root
  end

  def title_param
    "?title=#{URI.encode(title, /\W/)}" if title
  end
end
