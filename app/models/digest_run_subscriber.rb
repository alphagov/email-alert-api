class DigestRunSubscriber < ApplicationRecord
  validates :digest_run_id, :subscriber_id, presence: true
  belongs_to :digest_run
  belongs_to :subscriber

  def mark_complete!
    update_attributes!(completed_at: Time.now)
  end
end
