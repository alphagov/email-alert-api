class WeeklyDigestInitiatorWorker < DigestInitiatorWorker
  def perform(date = Date.current)
    DigestInitiatorService.call(date: date, range: Frequency::WEEKLY)
  end
end
