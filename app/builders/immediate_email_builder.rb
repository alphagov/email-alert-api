class ImmediateEmailBuilder
  def initialize(recipients_and_content)
    @recipients_and_content = recipients_and_content
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

  attr_reader :recipients_and_content

  def records
    @records ||= begin
      now = Time.zone.now
      recipients_and_content.map do |recipient_and_content|
        address = recipient_and_content.fetch(:address)
        content = recipient_and_content[:content_change] || recipient_and_content[:message]
        subscriptions = recipient_and_content.fetch(:subscriptions)

        {
          address: address,
          subject: subject(content),
          body: body(content, subscriptions.first, address),
          subscriber_id: recipient_and_content.fetch(:subscriber_id),
          created_at: now,
          updated_at: now,
        }
      end
    end
  end

  def subject(content)
    I18n.t!("emails.immediate.subject", title: content.title)
  end

  def body(content, subscription, address)
    list = subscription.subscriber_list

    <<~BODY
      #{I18n.t!('emails.immediate.opening_line')}

      # #{list.title}

      ---

      #{middle_section(list, content)}

      ---

      # #{I18n.t!('emails.immediate.footer_header')}

      #{I18n.t!('emails.immediate.footer_explanation')}

      #{list.title}

      # [Unsubscribe](#{PublicUrls.unsubscribe(subscription)})

      [#{I18n.t!('emails.immediate.footer_manage')}](#{PublicUrls.authenticate_url(address: address)})
    BODY
  end

  def middle_section(list, content)
    presenter = "#{content.class.name}Presenter".constantize
    section = presenter.call(content)

    section += "\n" + list.description if list.description.present?
    section
  end
end
