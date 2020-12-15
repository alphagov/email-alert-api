class SubscriptionConfirmationEmailBuilder < ApplicationBuilder
  def initialize(subscription:)
    @subscription = subscription
  end

  def call
    Email.create!(
      subject: subject,
      body: body,
      address: subscriber.address,
      subscriber_id: subscriber.id,
    )
  end

private

  attr_reader :subscription

  def subject
    "You’ve subscribed to: #{subscriber_list.title}"
  end

  def body
    <<~BODY
      # You’ve subscribed to GOV.UK emails

      #{I18n.t("emails.subscription_confirmation.frequency.#{subscription.frequency}")}

      #{title_and_description}

      Thanks
      GOV.UK emails
      https://www.gov.uk/help/update-email-notifications

      [Unsubscribe](#{PublicUrls.unsubscribe(subscription)})

      [#{I18n.t!('emails.footer_manage')}](#{PublicUrls.authenticate_url(address: subscriber.address)})
    BODY
  end

  def title_and_description
    title = subscriber_list.title
    return title if subscriber_list.description.blank?

    title + "\n\n" + subscriber_list.description
  end

  def subscriber
    @subscriber ||= subscription.subscriber
  end

  def subscriber_list
    @subscriber_list ||= subscription.subscriber_list
  end
end
