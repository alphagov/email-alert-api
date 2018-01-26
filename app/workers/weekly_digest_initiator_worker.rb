class WeeklyDigestInitiatorWorker < DigestInitiatorWorker
  def perform
    DigestInitiatorService.call(range: DigestRun::WEEKLY)
  end
end
