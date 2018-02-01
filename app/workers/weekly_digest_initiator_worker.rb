class WeeklyDigestInitiatorWorker < DigestInitiatorWorker
  def perform
    DigestInitiatorService.call(range: Frequency::WEEKLY)
  end
end
