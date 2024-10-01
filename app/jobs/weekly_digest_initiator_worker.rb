class WeeklyDigestInitiatorWorker < ApplicationWorker
  def perform(date = Date.current.to_s)
    run_with_advisory_lock(DigestRun, "#{date}-#{Frequency::WEEKLY}") do
      DigestInitiatorService.call(date: Date.parse(date), range: Frequency::WEEKLY)
    end
  end
end
