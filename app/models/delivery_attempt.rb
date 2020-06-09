class DeliveryAttempt < ApplicationRecord
  belongs_to :email

  validates :email, :status, :provider, presence: true

  FINAL_STATUSES = %i[delivered permanent_failure].freeze

  enum status: { sending: 0, delivered: 1, permanent_failure: 2, temporary_failure: 3, technical_failure: 4, internal_failure: 5 }
  enum provider: { pseudo: 0, notify: 1, delay: 2 }

  def has_final_status?
    self.class.final_status?(status)
  end

  def finished_sending_at
    sent_at || completed_at
  end

  def self.final_status?(status)
    FINAL_STATUSES.include?(status.to_sym)
  end
end
