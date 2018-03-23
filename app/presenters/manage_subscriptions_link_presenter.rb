class ManageSubscriptionsLinkPresenter
  def initialize(address:)
    @address = address
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    "[View and manage your subscriptions](#{url})"
  end

  private_class_method :new

private

  attr_reader :address

  def url
    base_path = "/email/authenticate?address=#{address}"
    PublicUrlService.url_for(base_path: base_path)
  end
end
