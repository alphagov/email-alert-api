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
        content = recipient_and_content.fetch(:content)
        subscription = recipient_and_content.fetch(:subscription)
        subscriber = subscription.subscriber

        {
          address: subscriber.address,
          subject: subject(content),
          body: body(content, subscription, subscriber),
          subscriber_id: subscriber.id,
          created_at: now,
          updated_at: now,
        }
      end
    end
  end

  def subject(content)
    "Update from GOV.UK for: #{content.title}"
  end

  def body(content, subscription, subscriber)
    list = subscription.subscriber_list

    <<~BODY
      Update from GOV.UK for:

      # #{list.title}

      ---

      #{middle_section(subscription, content)}

      ---

      #{FooterPresenter.call(subscriber, subscription)}
    BODY
  end

  def middle_section(subscription, content)
    subscriber_list = subscription.subscriber_list
    presenter = "#{content.class.name}Presenter".constantize
    section = presenter.call(content, subscription)

    source_url = SourceUrlPresenter.call(
      subscriber_list.url,
      utm_source: subscriber_list.slug,
      utm_content: "immediate",
    )

    section += "\n\n" + source_url if source_url
    section
  end
end
