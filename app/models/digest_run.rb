class DigestRun < ApplicationRecord
  DIGEST_RANGE_HOUR = 8

  validates :starts_at, :ends_at, :date, :range, presence: true
  before_validation :set_range_dates, on: :create
  validate :ends_at_is_in_the_past
  validate :weekly_digest_is_on_a_saturday

  has_many :digest_run_subscribers, dependent: :destroy
  has_many :subscribers, through: :digest_run_subscribers

  enum :range, { daily: 0, weekly: 1 }

  def mark_as_completed
    completed_time = digest_run_subscribers.maximum(:processed_at) || Time.zone.now
    update!(completed_at: completed_time)
  end

private

  def set_range_dates
    self.starts_at = Time.zone.parse("#{DIGEST_RANGE_HOUR}:00", starts_at_time)
    self.ends_at = Time.zone.parse("#{DIGEST_RANGE_HOUR}:00", date)
  end

  def ends_at_is_in_the_past
    return if ends_at < Time.zone.now

    errors.add(:date, "must be in the past, or today if after #{DIGEST_RANGE_HOUR}:00")
  end

  def weekly_digest_is_on_a_saturday
    return if daily? || date.saturday?

    errors.add(:date, "must be a Saturday for weekly digests")
  end

  def starts_at_time
    (daily? ? date - 1.day : date - 1.week)
  end
end
