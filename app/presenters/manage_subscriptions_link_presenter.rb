class ManageSubscriptionsLinkPresenter
  def initialize(address)
    @address = address
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    "[View, unsubscribe or change the frequency of your subscriptions](#{url})"
  end

  private_class_method :new

private

  attr_reader :address

  def url
    PublicUrls.authenticate_url(address: address)
  end
end
