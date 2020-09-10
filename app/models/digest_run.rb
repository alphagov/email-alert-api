class DigestRun < ApplicationRecord
  validates :starts_at, :ends_at, :date, :range, presence: true
  before_validation :set_range_dates, on: :create
  validate :ends_at_is_in_the_past
  validate :weekly_digest_is_on_a_saturday

  has_many :digest_run_subscribers, dependent: :destroy
  has_many :subscribers, through: :digest_run_subscribers

  enum range: { daily: 0, weekly: 1 }

  def mark_as_completed
    completed_time = digest_run_subscribers.maximum(:processed_at) || Time.zone.now
    update!(completed_at: completed_time)
  end

private

  def starts_at=(value)
    super
  end

  def ends_at=(value)
    super
  end

  def set_range_dates
    self.starts_at = configured_starts_at
    self.ends_at = configured_ends_at
  end

  def ends_at_is_in_the_past
    errors.add(:ends_at, "must be in the past") if ends_at >= Time.zone.now
  end

  def weekly_digest_is_on_a_saturday
    return if daily? || ends_at.saturday?

    errors.add(:ends_at, "must be a Saturday for weekly digests")
  end

  def configured_starts_at
    Time.zone.parse("#{digest_range_hour}:00", starts_at_time)
  end

  def configured_ends_at
    Time.zone.parse("#{digest_range_hour}:00", date)
  end

  def starts_at_time
    (daily? ? date - 1.day : date - 1.week)
  end

  def digest_range_hour
    ENV.fetch("DIGEST_RANGE_HOUR", 8).to_i
  end
end
