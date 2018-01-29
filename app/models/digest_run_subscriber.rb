class DigestRunSubscriber < ApplicationRecord
  validates :digest_run_id, :subscriber_id, presence: true
  belongs_to :digest_run
  belongs_to :subscriber

  scope :incomplete_for_run, ->(digest_run_id) { where(digest_run_id: digest_run_id).where(completed_at: nil) }

  def mark_complete!
    update_attributes!(completed_at: Time.now)
  end
end
