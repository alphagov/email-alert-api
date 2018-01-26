class WeeklyDigestInitiatorWorker < DigestInitiatorWorker
  def perform
    WeeklyDigestSchedulerService.call
  end
end
