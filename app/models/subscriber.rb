class Subscriber < ApplicationRecord
  with_options allow_nil: true do
    validates_with EmailAddressValidator, fields: [:address]
    validates_uniqueness_of :address, case_sensitive: false
  end

  validate :not_nullified_and_activated

  has_many :subscriptions, -> { not_deleted }
  has_many :subscriber_lists, through: :subscriptions
  has_many :digest_run_subscribers, dependent: :destroy
  has_many :digest_runs, through: :digest_run_subscribers

  scope :activated, -> { where(deactivated_at: nil) }
  scope :deactivated, -> { where.not(deactivated_at: nil) }
  scope :nullified, -> { where(address: nil) }
  scope :not_nullified, -> { where.not(address: nil) }

  def activated?
    deactivated_at.nil?
  end

  def activate!
    raise "Cannot activate if nullified." if nullified?
    raise "Already activated." if activated?

    update!(deactivated_at: nil)
  end

  def deactivated?
    deactivated_at.present?
  end

  def deactivate!(datetime: nil)
    raise "Already deactivated." if deactivated?

    update!(deactivated_at: datetime || Time.now)
  end

  def nullified?
    address.nil?
  end

  def nullify!
    raise "Already nullified." if nullified?
    raise "Must be deactivated first." unless deactivated?

    update!(address: nil)
  end

private

  def not_nullified_and_activated
    if nullified? && !deactivated?
      errors.add(:deactivated_at, "should be set to the deactivation date")
    end
  end
end
