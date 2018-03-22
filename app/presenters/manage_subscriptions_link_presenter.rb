class ManageSubscriptionsLinkPresenter
  def initialize(subscriber_id:)
    @subscriber_id = subscriber_id
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    "[View and manage your subscriptions](#{url})"
  end

  private_class_method :new

private

  attr_reader :subscriber_id

  def url
    base_path = "/email/authentication?id=#{subscriber_id}"
    PublicUrlService.url_for(base_path: base_path)
  end
end
