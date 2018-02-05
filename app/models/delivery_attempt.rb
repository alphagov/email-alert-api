class DeliveryAttempt < ApplicationRecord
  belongs_to :email

  validates :email, :status, :provider, presence: true

  enum status: { sending: 0, delivered: 1, permanent_failure: 2, temporary_failure: 3, technical_failure: 4 }
  enum provider: { pseudo: 0, notify: 1 }

  def self.latest_per_email
    from("(SELECT DISTINCT ON (email_id) * FROM delivery_attempts ORDER BY email_id, updated_at DESC) AS delivery_attempts")
  end

  def failure?
    permanent_failure? || temporary_failure? || technical_failure?
  end

  def should_report_failure?
    technical_failure?
  end

  def should_remove_subscriber?
    permanent_failure?
  end
end
