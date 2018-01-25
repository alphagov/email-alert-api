class DailyDigestInitiatorService
  include DigestInitiatorService
  LOCK_NAME = "daily_digest_initiator".freeze
  RANGE = DigestRun::DAILY.freeze
end
