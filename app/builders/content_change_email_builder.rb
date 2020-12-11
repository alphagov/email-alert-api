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
    <<~BODY
      #{I18n.t!('emails.content_change.opening_line')}

      ---
      #{presented_content_change(content_change, subscription)}
      ---
      #{footer(subscription, address).strip}
    BODY
  end

  def presented_content_change(content_change, subscription)
    copy = ContentChangePresenter.call(content_change)

    subscriber_list = subscription.subscriber_list
    if subscriber_list.description.present?
      copy += "\n#{subscriber_list.description}\n"
    end

    copy
  end

  def footer(subscription, address)
    <<~BODY
      #{permission_reminder(subscription.subscriber_list)}

      #{ManageSubscriptionsLinkPresenter.call(address)}
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
end
