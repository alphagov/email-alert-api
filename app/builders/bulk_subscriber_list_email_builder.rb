class BulkSubscriberListEmailBuilder < ApplicationBuilder
  BATCH_SIZE = 5000

  def initialize(subject:, body:, subscriber_lists:)
    @subject = subject
    @body = body
    @subscriber_lists = subscriber_lists
    @now = Time.zone.now
  end

  def call
    batches.flat_map do |batch|
      records = records_for_batch(batch.to_h)
      Email.insert_all!(records).pluck("id")
    end
  end

private

  attr_reader :subject, :body, :subscriber_lists, :now

  def records_for_batch(batch)
    subscriber_ids = batch.keys
    subscribers = Subscriber.find(subscriber_ids).index_by(&:id)

    subscription_ids = batch.values
    subscriptions = Subscription.find(subscription_ids).index_by(&:id)

    batch.map do |subscriber_id, subscriber_subscription_ids|
      subscriber = subscribers[subscriber_id]

      subscription = subscriptions.slice(*subscriber_subscription_ids)
        .values.max_by(&:created_at)

      {
        address: subscriber.address,
        subject: subject,
        body: email_body(subscriber, subscription),
        subscriber_id: subscriber_id,
        created_at: now,
        updated_at: now,
      }
    end
  end

  def email_body(subscriber, subscription)
    list = subscription.subscriber_list

    unsubscribe_url = PublicUrls.unsubscribe(
      subscription_id: subscription.id,
      subscriber_id: subscriber.id,
    )

    manage_url = PublicUrls.authenticate_url(
      address: subscriber.address,
    )

    <<~BODY
      #{body.gsub('%LISTURL%', list.url.to_s)}

      ---

      # Why am I getting this email?

      You asked GOV.UK to send you an email each time we add or update a page about:

      #{list.title}

      [Unsubscribe](#{unsubscribe_url})

      [Manage your email preferences](#{manage_url})
    BODY
  end

  def batches
    Subscription
      .active
      .where(subscriber_list: subscriber_lists)
      .subscription_ids_by_subscriber
      .each_slice(BATCH_SIZE)
  end
end
