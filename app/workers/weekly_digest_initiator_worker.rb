class WeeklyDigestInitiatorWorker < DigestInitiatorWorker
  def perform
    GC.start

    DigestInitiatorService.call(range: Frequency::WEEKLY)

    GC.start
  end
end
