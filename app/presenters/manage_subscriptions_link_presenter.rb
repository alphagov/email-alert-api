class ManageSubscriptionsLinkPresenter < ApplicationPresenter
  def initialize(subscriber)
    @subscriber = subscriber
  end

  def call
    "[View, unsubscribe or change the frequency of your subscriptions](#{url})"
  end

private

  attr_reader :subscriber

  def url
    PublicUrls.manage_url(subscriber)
  end
end
