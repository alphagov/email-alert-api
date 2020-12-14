class MessageEmailBuilder
  def initialize(recipients_and_messages)
    @recipients_and_messages = recipients_and_messages
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    Email.timed_bulk_insert(records, ImmediateEmailGenerationService::BATCH_SIZE)
         .pluck("id")
  end

  private_class_method :new

private

  attr_reader :recipients_and_messages

  def records
    @records ||= begin
      now = Time.zone.now

      recipients_and_messages.map do |x|
        {
          address: x[:address],
          subject: subject(x[:message]),
          body: body(x[:message], x[:subscriptions].first, x[:address]),
          subscriber_id: x[:subscriber_id],
          created_at: now,
          updated_at: now,
        }
      end
    end
  end

  def subject(message)
    I18n.t!("emails.message.subject", title: message.title)
  end

  def body(message, subscription, address)
    list = subscription.subscriber_list

    <<~BODY
      #{I18n.t!('emails.message.opening_line')}

      # #{list.title}

      ---

      #{middle_section(list, message)}

      ---

      # #{I18n.t!('emails.message.footer_header')}

      #{I18n.t!('emails.message.footer_explanation')}

      #{list.title}

      # [Unsubscribe](#{PublicUrls.unsubscribe(subscription)})

      [#{I18n.t!('emails.message.footer_manage')}](#{PublicUrls.authenticate_url(address: address)})
    BODY
  end

  def middle_section(list, message)
    section = MessagePresenter.call(message)
    section += "\n" + list.description if list.description.present?
    section
  end
end
