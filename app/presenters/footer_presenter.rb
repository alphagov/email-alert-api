class FooterPresenter < ApplicationPresenter
  def initialize(subscriber, subscription)
    @subscription = subscription
    @subscriber = subscriber
    @subscriber_list = subscription.subscriber_list
  end

  def call
    result = <<~FOOTER
      # Why am I getting this email?

      #{I18n.t("emails.footer.#{subscription.frequency}")}

      #{subscriber_list.title}

      [Unsubscribe](#{unsubscribe_url})

      [Manage your email preferences](#{manage_url})
    FOOTER

    result.strip
  end

private

  attr_reader :subscription, :subscriber, :subscriber_list

  def unsubscribe_url
    PublicUrls.unsubscribe(
      subscription,
      utm_source: subscriber_list.slug,
      utm_content: subscription.frequency,
    )
  end

  def manage_url
    PublicUrls.manage_url(
      subscriber,
      utm_source: subscriber_list.slug,
      utm_content: subscription.frequency,
    )
  end
end
