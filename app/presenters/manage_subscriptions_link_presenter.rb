class ManageSubscriptionsLinkPresenter < ApplicationPresenter
  def initialize(address)
    @address = address
  end

  def call
    "[View, unsubscribe or change the frequency of your subscriptions](#{url})"
  end

private

  attr_reader :address

  def url
    PublicUrls.authenticate_url(address: address)
  end
end
