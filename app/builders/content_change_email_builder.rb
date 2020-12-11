class ContentChangeEmailBuilder
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

        {
          address: address,
          subject: subject(recipient_and_content.fetch(:content_change)),
          body: body(recipient_and_content.fetch(:content_change), recipient_and_content.fetch(:subscriptions).first, address),
          subscriber_id: recipient_and_content.fetch(:subscriber_id),
          created_at: now,
          updated_at: now,
        }
      end
    end
  end

  def subject(content_change)
    I18n.t!("emails.content_change.subject", title: content_change.title)
  end

  def body(content_change, subscription, address)
    list = subscription.subscriber_list

    <<~BODY
      #{I18n.t!('emails.content_change.opening_line')}

      # #{list.title}

      ---

      #{middle_section(list, content_change)}

      ---

      # #{I18n.t!('emails.content_change.footer_header')}

      #{I18n.t!('emails.content_change.footer_explanation')}

      #{list.title}

      # [Unsubscribe](#{PublicUrls.unsubscribe(subscription)})

      [#{I18n.t!('emails.content_change.footer_manage')}](#{PublicUrls.authenticate_url(address: address)})
    BODY
  end

  def middle_section(list, content_change)
    section = ContentChangePresenter.call(content_change)
    section += "\n" + list.description if list.description.present?
    section
  end
end
