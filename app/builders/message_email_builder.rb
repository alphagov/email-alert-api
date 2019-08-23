class MessageEmailBuilder
  def initialize(recipients_and_messages)
    @recipients_and_messages = recipients_and_messages
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    Email.import!(columns, records)
  end

  private_class_method :new

private

  attr_reader :recipients_and_messages

  def records
    recipients_and_messages.map do |address:, message:, subscriptions:, subscriber_id:|
      [
        address,
        subject(message),
        body(message, subscriptions, address),
        subscriber_id,
      ]
    end
  end

  def columns
    %i(address subject body subscriber_id)
  end

  def subject(message)
    I18n.t!("emails.message.subject", title: message.title)
  end

  def body(message, subscriptions, address)
    copy = <<~BODY
      #{I18n.t!('emails.message.opening_line')}

      ---
      #{MessagePresenter.call(message)}
    BODY

    if subscriptions.any?
      copy += <<~BODY
        ---
        #{permission_reminder(subscriptions.first.subscriber_list)}

        #{ManageSubscriptionsLinkPresenter.call(address)}
      BODY
    end

    copy
  end

  def permission_reminder(subscriber_list)
    topic = if subscriber_list.url
              "[#{subscriber_list.title}](#{Plek.new.website_root}#{subscriber_list.url})"
            else
              subscriber_list.title
            end

    I18n.t!("emails.message.permission_reminder", topic: topic)
  end
end
