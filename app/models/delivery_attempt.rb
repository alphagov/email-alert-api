class DeliveryAttempt < ApplicationRecord
  belongs_to :email

  validates :email, :status, :provider, :reference, presence: true

  enum status: %i(created sending delivered permanent_failure temporary_failure technical_failure internal_failure)
  enum provider: %i(psuedo notify)

  def failure?
    permanent_failure? || temporary_failure? || technical_failure? || internal_failure?
  end

  def should_retry?
    temporary_failure? || technical_failure?
  end

  def should_report_failure?
    internal_failure?
  end

  def should_remove_subscriber?
    permanent_failure?
  end
end
