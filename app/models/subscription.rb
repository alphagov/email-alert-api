class Subscription < ApplicationRecord
  belongs_to :subscriber
  belongs_to :subscriber_list

  has_many :subscription_contents, dependent: :destroy

  enum frequency: { immediately: 0, daily: 1, weekly: 2 }

  enum source: {
    user_signed_up: 0,
    frequency_changed: 1,
    imported: 2, # Historical (from govDelivery migration)
    subscriber_list_changed: 3,
    bulk_immediate_to_digest: 4, # Historical (for a one-off migration)
    subscriber_merged: 5,
    support_task: 6,
  }, _prefix: true

  enum ended_reason: {
    unsubscribed: 0,
    non_existent_email: 1,
    frequency_changed: 2,
    subscriber_list_changed: 3,
    marked_as_spam: 4,
    unpublished: 5, # Unused since 5eeda132 (can be removed after a year)
    bulk_immediate_to_digest: 6, # Potentially unused (for a one-off migration)
    subscriber_merged: 7,
    bulk_unsubscribed: 8,
    bulk_migrated: 9,
  }, _prefix: :ended

  scope :active, -> { where(ended_at: nil) }
  scope :ended, -> { where.not(ended_at: nil) }

  scope :active_on,
        lambda { |date|
          where("subscriptions.created_at <= ?", date)
            .where("subscriptions.ended_at IS NULL OR subscriptions.ended_at > ?", date)
        }

  scope :for_content_change,
        lambda { |content_change|
          joins(subscriber_list: :matched_content_changes)
            .where(matched_content_changes: { content_change_id: content_change.id })
        }

  scope :for_message,
        lambda { |message|
          joins(subscriber_list: :matched_messages)
            .where(matched_messages: { message_id: message.id })
        }

  scope :dedup_by_subscriber,
        lambda {
          order("subscriptions.subscriber_id DESC, subscriptions.created_at desc")
            .pluck(Arel.sql("DISTINCT ON (subscriptions.subscriber_id) subscriber_id, subscriptions.id as id"))
            .map(&:last)
        }

  def as_json(options = {})
    options[:except] ||= %i[signon_user_uid subscriber_list_id subscriber_id]
    options[:include] ||= %i[subscriber_list subscriber]
    super(options)
  end

  def active?
    ended_at.nil?
  end

  def ended?
    ended_at.present?
  end

  def end(reason:, datetime: nil, ended_email_id: nil)
    raise "Already ended." if ended?

    update!(
      ended_reason: reason,
      ended_at: datetime || Time.zone.now,
      ended_email_id:,
    )

    Metrics.unsubscribed(reason)
  end
end
