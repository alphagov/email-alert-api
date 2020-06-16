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
end
