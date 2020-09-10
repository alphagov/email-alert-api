class DailyDigestInitiatorWorker < DigestInitiatorWorker
  def perform(date = Date.current)
    DigestInitiatorService.call(date: date, range: Frequency::DAILY)
  end
end
