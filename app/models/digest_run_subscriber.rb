class DigestRunSubscriber < ApplicationRecord
  validates :digest_run_id, :subscriber_id, presence: true
  belongs_to :digest_run
  belongs_to :subscriber

  scope :incomplete_for_run, ->(digest_run_id) { where(digest_run_id: digest_run_id).where(completed_at: nil) }

  def mark_complete!
    update!(completed_at: Time.zone.now)
  end

  def completed?
    completed_at.present?
  end
end
