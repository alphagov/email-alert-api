class DigestRunSubscriber < ApplicationRecord
  belongs_to :digest_run
  belongs_to :subscriber

  scope :incomplete_for_run, ->(digest_run_id) { where(digest_run_id: digest_run_id).where(completed_at: nil) }

  def self.populate(digest_run, subscriber_ids)
    now = Time.zone.now
    records = subscriber_ids.map do |subscriber_id|
      {
        digest_run_id: digest_run.id,
        subscriber_id: subscriber_id,
        created_at: now,
        updated_at: now,
      }
    end

    insert_all!(records).pluck("id")
  end

  def mark_complete!
    update!(completed_at: Time.zone.now)
  end

  def completed?
    completed_at.present?
  end
end
