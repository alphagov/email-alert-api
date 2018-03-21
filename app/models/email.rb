class Email < ApplicationRecord
  has_many :delivery_attempts

  scope :archivable, lambda {
    where(archived_at: nil).where.not(finished_sending_at: nil)
  }

  scope :deleteable, lambda {
    where.not(archived_at: nil).where("finished_sending_at < ?", 14.days.ago)
  }

  enum status: { pending: 0, sent: 1, failed: 2 }
  enum failure_reason: { permanent_failure: 0, retries_exhausted_failure: 1 }

  validates :address, :subject, :body, presence: true
end
