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
      records = records_for_batch(batch)
      Email.insert_all!(records).pluck("id")
    end
  end

private

  attr_reader :subject, :body, :subscriber_lists, :now

  def records_for_batch(subscriber_ids)
    subscribers = Subscriber
      .find(subscriber_ids)
      .index_by(&:id)

    subscriber_ids.map do |subscriber_id|
      subscriber = subscribers[subscriber_id]

      {
        address: subscriber.address,
        subject: subject,
        body: body,
        subscriber_id: subscriber_id,
        created_at: now,
        updated_at: now,
      }
    end
  end

  def batches
    Subscription
      .active
      .where(subscriber_list: subscriber_lists)
      .distinct
      .pluck(:subscriber_id)
      .each_slice(BATCH_SIZE)
  end
end
