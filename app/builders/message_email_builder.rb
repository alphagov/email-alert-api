class MessageEmailBuilder
  def initialize(recipients_and_messages)
    @recipients_and_messages = recipients_and_messages
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    return [] if records.empty?

    Email.timed_bulk_insert(records, ProcessAndGenerateEmailsWorker::BATCH_SIZE)
         .pluck("id")
  end

  private_class_method :new

private

  attr_reader :recipients_and_messages

  def records
    @records ||= begin
      now = Time.zone.now

      recipients_and_messages.map do |address:, message:, subscriptions:, subscriber_id:|
        {
          address: address,
          subject: subject(message),
          body: body(message, subscriptions, address),
          subscriber_id: subscriber_id,
          created_at: now,
          updated_at: now,
        }
      end
    end
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
      subscriber_list = subscriptions.first.subscriber_list

      if subscriber_list.description.present?
        copy += "#{subscriber_list.description}\n"
      end

      copy += <<~BODY
        ---
        #{permission_reminder(subscriber_list)}

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
