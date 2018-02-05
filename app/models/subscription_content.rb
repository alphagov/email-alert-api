class SubscriptionContent < ApplicationRecord
  belongs_to :subscription
  belongs_to :content_change
  belongs_to :email, optional: true

  scope :immediate, -> { where(digest_run_subscriber_id: nil) }
  scope :digest, -> { where.not(digest_run_subscriber_id: nil) }
end
