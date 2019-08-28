class ContentChangeEmailBuilder
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
        address = recipient_and_content.fetch(:address),
        subject(recipient_and_content.fetch(:content_change)),
        body(recipient_and_content.fetch(:content_change), recipient_and_content.fetch(:subscriptions), address),
        recipient_and_content.fetch(:subscriber_id),
      ]
    end
  end

  def subject(content_change)
    I18n.t!("emails.content_change.subject", title: content_change.title)
  end

  def columns
    %i(address subject body subscriber_id)
  end

  def body(content_change, subscriptions, address)
    <<~BODY
      #{I18n.t!('emails.content_change.opening_line')}

      ---
      #{ContentChangePresenter.call(content_change)}
      ---
      #{footer(subscriptions, address).strip}
    BODY
  end

  def footer(subscriptions, address)
    return feedback_link if subscriptions.empty?

    <<~BODY
      #{permission_reminder(subscriptions.first.subscriber_list)}

      #{ManageSubscriptionsLinkPresenter.call(address)}

      #{feedback_link}
    BODY
  end

  def permission_reminder(subscriber_list)
    topic = if subscriber_list.url
              "[#{subscriber_list.title}](#{Plek.new.website_root}#{subscriber_list.url})"
            else
              subscriber_list.title
            end

    I18n.t!("emails.content_change.permission_reminder", topic: topic)
  end

  def feedback_link
    I18n.t!("emails.feedback_link",
            survey_link: I18n.t!("emails.content_change.survey_link"),
            feedback_link: "#{Plek.new.website_root}/contact")
  end
end
