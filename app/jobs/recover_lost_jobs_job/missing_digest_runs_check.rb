class RecoverLostJobsJob::MissingDigestRunsCheck
  def call
    recover(DailyDigestInitiatorJob, non_existent_daily_digests)
    recover(WeeklyDigestInitiatorJob, non_existent_weekly_digests)
  end

private

  def non_existent_daily_digests
    expected_digest_week
      .map { |date| DigestRun.find_or_initialize_by(date:, range: :daily) }
      .reject(&:persisted?)
  end

  def non_existent_weekly_digests
    [expected_digest_week.find(&:saturday?)]
      .map { |date| DigestRun.find_or_initialize_by(date:, range: :weekly) }
      .reject(&:persisted?)
  end

  def expected_digest_week
    digestion_time = Time.zone.parse("#{DigestRun::DIGEST_RANGE_HOUR}:00")
    cutoff_with_delay = digestion_time + 1.hour
    end_date = Time.zone.now > cutoff_with_delay ? Time.zone.today : Time.zone.yesterday
    (end_date - 6.days)..end_date
  end

  def recover(worker, digests)
    digests.each { |digest| worker.perform_async(digest.date.to_s) }
  end
end
