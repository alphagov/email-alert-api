class DigestRun < ApplicationRecord
  validates :starts_at, :ends_at, :date, :range, presence: true
  before_validation :set_range_dates, on: :create
  validate :ends_at_is_in_the_past

  enum range: { daily: 0, weekly: 1 }

  DAILY = "daily".freeze
  WEEKLY = "weekly".freeze

private

  def set_range_dates
    self.starts_at = configured_starts_at
    self.ends_at = configured_ends_at
  end

  def ends_at_is_in_the_past
    errors.add(:ends_at, "must be in the past") if ends_at >= Time.now
  end

  def configured_starts_at
    Time.parse("#{digest_range_hour}:00", starts_at_date)
  end

  def configured_ends_at
    Time.parse("#{digest_range_hour}:00", Time.now)
  end

  def starts_at_date
    daily? ? 1.day.ago : 1.week.ago
  end

  def digest_range_hour
    ENV.fetch("DIGEST_RANGE_HOUR", 8).to_i
  end
end
