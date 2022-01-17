class FooterPresenter
  include Callable

  def initialize(subscriber, subscription, omit_unsubscribe_link: false)
    @subscription = subscription
    @subscriber = subscriber
    @subscriber_list = subscription.subscriber_list
    @omit_unsubscribe_link = omit_unsubscribe_link
  end

  def call
    result = <<~FOOTER
      # Why am I getting this email?

      #{I18n.t("emails.footer.#{subscription.frequency}")}

      #{subscriber_list.title}

      #{unsubscribe_and_change}
    FOOTER

    result.strip
  end

private

  attr_reader :subscription, :subscriber, :subscriber_list, :omit_unsubscribe_link

  def unsubscribe_and_change
    result = "[Change your email preferences](#{manage_url})"
    unless omit_unsubscribe_link
      result = "[Unsubscribe](#{unsubscribe_url})\n\n#{result}"
    end

    result
  end

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
