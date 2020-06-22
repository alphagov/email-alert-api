class SubscriptionContent < ApplicationRecord
  # Any validations added this to this model won't be applied on record
  # creation as this table is populated by the #insert_all bulk method

  belongs_to :subscription
  belongs_to :digest_run_subscriber, optional: true
  belongs_to :email, optional: true

  # A subscription content should always have one of these and not both
  belongs_to :content_change, optional: true
  belongs_to :message, optional: true

  scope :immediate, -> { where(digest_run_subscriber_id: nil) }
  scope :digest, -> { where.not(digest_run_subscriber_id: nil) }

  def self.populate_for_content(content, records)
    base = case content
           when ContentChange
             { content_change_id: content.id }
           when Message
             { message_id: content.id }
           else
             raise ArgumentError, "Expected #{content.class.name} to be a "\
                                  "ContentChange or a Message"
           end

    now = Time.zone.now

    attributes = records.map do |record|
      base.merge(created_at: now, updated_at: now).merge(record)
    end

    SubscriptionContent.insert_all!(attributes)
  end
end
