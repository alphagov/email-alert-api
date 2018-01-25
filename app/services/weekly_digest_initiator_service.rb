class WeeklyDigestInitiatorService
  include DigestInitiatorService
  LOCK_NAME = "weekly_digest_initiator".freeze
  RANGE = DigestRun::WEEKLY.freeze
end
