class DeliveryAttempt < ApplicationRecord
  belongs_to :email

  validates :email, :status, :provider, presence: true

  enum status: { sending: 0, delivered: 1, permanent_failure: 2, temporary_failure: 3, technical_failure: 4 }
  enum provider: { pseudo: 0, notify: 1 }

  def self.latest_per_email
    inner = group(:email_id).select("email_id AS id, MAX(updated_at) AS max")
    joins("JOIN (#{inner.to_sql}) x ON email_id = x.id and updated_at = x.max")
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
