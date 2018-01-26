class DailyDigestInitiatorWorker < DigestInitiatorWorker
  def perform
    DailyDigestSchedulerService.call
  end
end
