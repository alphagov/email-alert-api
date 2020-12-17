class ImmediateEmailBuilder < ApplicationBuilder
  def initialize(recipients_and_content)
    @recipients_and_content = recipients_and_content
  end

  def call
    Email.timed_bulk_insert(records, ImmediateEmailGenerationService::BATCH_SIZE)
         .pluck("id")
  end

private

  attr_reader :recipients_and_content

  def records
    @records ||= begin
      now = Time.zone.now
      recipients_and_content.map do |recipient_and_content|
        address = recipient_and_content.fetch(:address)
        content = recipient_and_content.fetch(:content)
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
    "Update from GOV.UK for: #{content.title}"
  end

  def body(content, subscription, address)
    list = subscription.subscriber_list

    <<~BODY
      Update from GOV.UK for:

      # #{list.title}

      ---

      #{middle_section(list, content)}

      ---

      # Why am I getting this email?

      You asked GOV.UK to send you an email each time we add or update a page about:

      #{list.title}

      [Unsubscribe](#{unsubscribe_url(subscription)})

      [Manage your email preferences](#{PublicUrls.authenticate_url(address: address)})
    BODY
  end

  def middle_section(list, content)
    presenter = "#{content.class.name}Presenter".constantize
    section = presenter.call(content).strip

    section += "\n\n" + list.description if list.description.present?
    section
  end

  def unsubscribe_url(subscription)
    PublicUrls.unsubscribe(
      subscription_id: subscription.id,
      subscriber_id: subscription.subscriber_id,
    )
  end
end
