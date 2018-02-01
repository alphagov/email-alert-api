class DailyDigestInitiatorWorker < DigestInitiatorWorker
  def perform
    DigestInitiatorService.call(range: Frequency::DAILY)
  end
end
