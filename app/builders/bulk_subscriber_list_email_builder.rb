class BulkSubscriberListEmailBuilder < ApplicationBuilder
  BATCH_SIZE = 5000

  def initialize(subject:, body:, subscriber_lists:)
    @subject = subject
    @body = body
    @subscriber_lists = subscriber_lists
    @now = Time.zone.now
  end

  def call
    ActiveRecord::Base.transaction do
      batches.flat_map do |subscription_ids|
        records = records_for_batch(subscription_ids)
        Email.insert_all!(records).pluck("id")
      end
    end
  end

private

  attr_reader :subject, :body, :subscriber_lists, :now

  def records_for_batch(subscription_ids)
    subscriptions = Subscription
      .includes(:subscriber)
      .find(subscription_ids)

    subscriptions.map do |subscription|
      subscriber = subscription.subscriber

      {
        address: subscriber.address,
        subject: subject,
        body: email_body(subscriber, subscription),
        subscriber_id: subscriber.id,
        created_at: now,
        updated_at: now,
      }
    end
  end

  def email_body(subscriber, subscription)
    <<~BODY
      #{BulkEmailBodyPresenter.call(body, subscription.subscriber_list)}

      ---

      #{FooterPresenter.call(subscriber, subscription)}
    BODY
  end

  def batches
    Subscription
      .active
      .where(subscriber_list: subscriber_lists)
      .dedup_by_subscriber
      .each_slice(BATCH_SIZE)
  end
end
