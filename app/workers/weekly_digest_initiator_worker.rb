class WeeklyDigestInitiatorWorker < DigestInitiatorWorker
  def perform
    WeeklyDigestInitiatorService.call
  end
end
