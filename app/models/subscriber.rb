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

  scope :nullified, -> { where(address: nil) }
  scope :deactivated, -> { where.not(deactivated_at: nil) }
  scope :activated, -> { where(deactivated_at: nil) }

  def nullify!
    raise "Already nullified." if address.nil?
    raise "Must be deactivated first." if deactivated_at.nil?

    update!(address: nil)
  end

  def deactivate!(datetime: nil)
    raise "Already deactivated." unless deactivated_at.nil?

    update!(deactivated_at: datetime || Time.now)
  end

  def activate!
    raise "Cannot activate as the address is nil." if address.nil?
    raise "Already activated." if deactivated_at.nil?

    update!(deactivated_at: nil)
  end

private

  def not_nullified_and_activated
    if address.nil? && deactivated_at.nil?
      errors.add(:deactivated_at, "should be set to the deactivation date")
    end
  end
end
