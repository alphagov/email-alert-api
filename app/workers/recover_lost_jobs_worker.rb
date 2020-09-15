class RecoverLostJobsWorker
  include Sidekiq::Worker

  def perform
    recover(ProcessContentChangeWorker, old_unprocessed(ContentChange).pluck(:id))
    recover(ProcessMessageWorker, old_unprocessed(Message).pluck(:id))
    recover(DigestEmailGenerationWorker, old_unprocessed(DigestRunSubscriber).pluck(:id))
    recover(DailyDigestInitiatorWorker, old_unprocessed(DigestRun.daily).pluck(:date).map(&:to_s))
    recover(WeeklyDigestInitiatorWorker, old_unprocessed(DigestRun.weekly).pluck(:date).map(&:to_s))
    recover(DailyDigestInitiatorWorker, non_existent_daily_digests.map(&:date).map(&:to_s))
    recover(WeeklyDigestInitiatorWorker, non_existent_weekly_digests.map(&:date).map(&:to_s))
  end

private

  def old_unprocessed(scope)
    scope.where(processed_at: nil).where("created_at <= ?", 1.hour.ago)
  end

  def non_existent_daily_digests
    expected_digest_week
      .map { |date| DigestRun.find_or_initialize_by(date: date, range: :daily) }
      .reject(&:persisted?)
  end

  def non_existent_weekly_digests
    [expected_digest_week.find(&:saturday?)]
      .map { |date| DigestRun.find_or_initialize_by(date: date, range: :weekly) }
      .reject(&:persisted?)
  end

  def expected_digest_week
    digestion_time = Time.zone.parse("#{DigestRun::DIGEST_RANGE_HOUR}:00")
    cutoff_with_delay = digestion_time + 1.hour
    end_date = Time.zone.now > cutoff_with_delay ? Time.zone.today : Time.zone.yesterday
    (end_date - 6.days)..end_date
  end

  def recover(worker, work)
    work.each { |arg| worker.perform_async(arg) }
  end
end
