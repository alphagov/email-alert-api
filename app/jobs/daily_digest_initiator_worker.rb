class DailyDigestInitiatorWorker < ApplicationWorker
  def perform(date = Date.current.to_s)
    run_with_advisory_lock(DigestRun, "#{date}-#{Frequency::DAILY}") do
      DigestInitiatorService.call(date: Date.parse(date), range: Frequency::DAILY)
    end
  end
end
