require "govuk_personalisation"

class LinkedAccountEmailBuilder
  include Callable

  def initialize(subscriber:)
    @subscriber = subscriber
  end

  def call
    Email.create!(
      subject:,
      body:,
      address: subscriber.address,
      subscriber_id: subscriber.id,
    )
  end

private

  attr_reader :subscriber

  def subject
    "Use your GOV.UK account to manage your GOV.UK email subscriptions in one place"
  end

  def body
    <<~BODY
      Hello

      All the GOV.UK email subscriptions for #{subscriber.address} have now been moved to your new GOV.UK account.

      You can now use your account to see and manage the emails you get about:

      #{bulleted_active_subscriptions}

      Sign in to your account: #{sign_in_url}

      If you have any questions or something does not look right, contact us: #{contact_url}

      ----

      Do not reply to this email — it’s an automatic message from an unmonitored account.
    BODY
  end

  def bulleted_active_subscriptions
    items = subscriber.active_subscriptions.map do |subscription|
      "- #{subscription.subscriber_list.title}"
    end
    items.join("\n")
  end

  def sign_in_url
    GovukPersonalisation::Urls.sign_in
  end

  def contact_url
    "https://signin.account.gov.uk/contact-us?supportType=PUBLIC"
  end
end
