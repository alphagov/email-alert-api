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
    I18n.t!("message.subject", title: message.title)
  end

  def body(message, subscriptions, address)
    copy = <<~BODY
      #{I18n.t!('message.opening_line')}

      ---
      #{MessagePresenter.call(message)}
    BODY

    if subscriptions.any?
      copy += <<~BODY
        ---
        #{permission_reminder(subscriptions)}

        #{ManageSubscriptionsLinkPresenter.call(address: address)}
      BODY
    end

    copy
  end

  def permission_reminder(subscriptions)
    title = subscriptions.first.subscriber_list.title
    topic = I18n.t!("message.permission_reminder_topic",
                    title: title)
    I18n.t!("permission_reminder",
            frequency: "immediate",
            permission_reminder_topic: topic)
  end
end
