class ImmediateEmailBuilder < ApplicationBuilder
  def initialize(content, subscriptions)
    @content = content
    @subscriptions = subscriptions
  end

  def call
    Email.timed_bulk_insert(records, ImmediateEmailGenerationService::BATCH_SIZE)
         .pluck("id")
  end

private

  attr_reader :content, :subscriptions

  def records
    @records ||= begin
      now = Time.zone.now
      subscriptions.map do |subscription|
        subscriber = subscription.subscriber

        {
          address: subscriber.address,
          subject: subject,
          body: body(subscription, subscriber),
          subscriber_id: subscriber.id,
          created_at: now,
          updated_at: now,
        }
      end
    end
  end

  def subject
    "Update from GOV.UK for: #{content.title}"
  end

  def body(subscription, subscriber)
    list = subscription.subscriber_list

    <<~BODY
      Update from GOV.UK for:

      # #{list.title}

      ---

      #{middle_section(subscription)}

      ---

      #{FooterPresenter.call(subscriber, subscription)}
    BODY
  end

  def middle_section(subscription)
    subscriber_list = subscription.subscriber_list
    presenter = "#{content.class.name}Presenter".constantize
    section = presenter.call(content, subscription)

    source_url = SourceUrlPresenter.call(
      subscriber_list.url,
      utm_source: subscriber_list.slug,
      utm_content: "immediate",
    )

    section += "\n\n#{source_url}" if source_url
    section
  end
end
