class ImmediateEmailBuilder
  include Callable

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
          subject:,
          body: body(subscription, subscriber),
          subscriber_id: subscriber.id,
          created_at: now,
          updated_at: now,
          content_id: content.try(:content_id),
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

      #{FooterPresenter.call(subscriber, subscription, omit_unsubscribe_link: omit_footer_unsubscribe_link)}
    BODY
  end

  def middle_section(subscription)
    presenter = "#{content.class.name}Presenter".constantize
    presenter.call(content, subscription)
  end

  def omit_footer_unsubscribe_link
    if content.respond_to?(:omit_footer_unsubscribe_link)
      content.omit_footer_unsubscribe_link
    else
      false
    end
  end
end
