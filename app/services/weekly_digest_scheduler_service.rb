class WeeklyDigestSchedulerService
  include DigestSchedulerService
  LOCK_NAME = "weekly_digest_scheduler".freeze
  RANGE = DigestRun::WEEKLY.freeze
end
