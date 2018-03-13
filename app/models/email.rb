class Email < ApplicationRecord
  has_many :delivery_attempts

  scope :archivable, lambda {
    where(archived_at: nil).where.not(finished_sending_at: nil)
  }

  scope :deleteable, lambda {
    where.not(archived_at: nil).where("finished_sending_at < ?", 14.days.ago)
  }

  validates :address, :subject, :body, presence: true

  # Mark an email to indicate the process of sending it is complete
  def finish_sending(delivery_attempt)
    raise ArgumentError, "DeliveryAttempt for different email" if delivery_attempt.email_id != id
    update!(finished_sending_at: delivery_attempt.sent_at)
  end
end
