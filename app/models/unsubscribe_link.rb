class UnsubscribeLink
  def self.for(subscriptions)
    subscriptions.map { |s| new(s) }
  end

  def initialize(subscription)
    self.subscription = subscription
  end

  def title
    subscription.subscriber_list.title
  end

  def url
    PublicUrlService.unsubscribe_url(uuid: subscription.uuid, title: title)
  end

private

  attr_accessor :subscription
end
