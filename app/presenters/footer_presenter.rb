class FooterPresenter < ApplicationPresenter
  def initialize(subscriber, subscription)
    @subscription = subscription
    @subscriber = subscriber
  end

  def call
    result = <<~FOOTER
      # Why am I getting this email?

      #{I18n.t("emails.footer.#{subscription.frequency}")}

      #{subscription.subscriber_list.title}

      [Unsubscribe](#{unsubscribe_url})

      [Manage your email preferences](#{manage_url})
    FOOTER

    result.strip
  end

private

  attr_reader :subscription, :subscriber

  def unsubscribe_url
    PublicUrls.unsubscribe(subscription)
  end

  def manage_url
    PublicUrls.authenticate_url(address: subscriber.address)
  end
end
