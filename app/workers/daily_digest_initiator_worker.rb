class DailyDigestInitiatorWorker < DigestInitiatorWorker
  def perform
    GC.start

    DigestInitiatorService.call(range: Frequency::DAILY)

    GC.start
  end
end
