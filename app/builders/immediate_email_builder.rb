class ImmediateEmailBuilder
  def initialize(recipients_and_content)
    @recipients_and_content = recipients_and_content
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    Email.import!(columns, records)
  end

  private_class_method :new

private

  attr_reader :recipients_and_content

  def records
    recipients_and_content.map do |recipient_and_content|
      [
        recipient_and_content.fetch(:address),
        subject(recipient_and_content.fetch(:content_change)),
        body(recipient_and_content.fetch(:content_change), recipient_and_content.fetch(:subscriptions)),
        recipient_and_content.fetch(:subscriber_id),
      ]
    end
  end

  def columns
    %i(address subject body subscriber_id)
  end

  def subject(content_change)
    "GOV.UK update – #{content_change.title}"
  end

  def body(content_change, subscriptions)
    if Array(subscriptions).empty?
      presented_content_change(content_change)
    else
      <<~BODY
        #{presented_content_change(content_change)}
        ---
        You’re getting this email because you subscribed to ‛#{subscriptions.first.subscriber_list.title}’ updates on GOV.UK.

        #{presented_unsubscribe_links(subscriptions)}
        [View and manage your subscriptions](/magic-manage-link)

        \u00A0

        ^Is this email useful? [Answer some questions to tell us more](https://www.smartsurvey.co.uk/s/govuk-email/?f=immediate).
      BODY
    end
  end

  def presented_content_change(content_change)
    ContentChangePresenter.call(content_change, frequency: "immediate")
  end

  def presented_unsubscribe_links(subscriptions)
    links_array = subscriptions.map do |subscription|
      UnsubscribeLinkPresenter.call(
        id: subscription.id,
        title: subscription.subscriber_list.title,
      )
    end

    links_array.join("\n")
  end
end
