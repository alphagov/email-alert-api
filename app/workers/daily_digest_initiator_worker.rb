class DailyDigestInitiatorWorker < DigestInitiatorWorker
  def perform
    DailyDigestInitiatorService.call
  end
end
