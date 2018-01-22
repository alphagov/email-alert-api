class DailyDigestSchedulerService
  include DigestSchedulerService
  LOCK_NAME = "daily_digest_scheduler".freeze
  RANGE = DigestRun::DAILY.freeze
end
