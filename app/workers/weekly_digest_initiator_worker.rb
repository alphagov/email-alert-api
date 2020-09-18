class WeeklyDigestInitiatorWorker < DigestInitiatorWorker
  def perform(date = Date.current.to_s)
    DigestInitiatorService.call(date: Date.parse(date), range: Frequency::WEEKLY)
  end
end
