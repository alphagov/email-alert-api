class DailyDigestInitiatorWorker < DigestInitiatorWorker
  def perform
    DigestInitiatorService.call(range: DigestRun::DAILY)
  end
end
