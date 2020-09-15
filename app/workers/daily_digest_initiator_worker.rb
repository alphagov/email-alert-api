class DailyDigestInitiatorWorker < DigestInitiatorWorker
  sidekiq_options lock: :until_executed,
                  unique_args: :uniqueness_with, # in upcoming version 7 of sidekiq-unique-jobs, :unique_args is replaced with :lock_args
                  on_conflict: :log

  def self.uniqueness_with(args)
    [args.first || Date.current.to_s]
  end

  def perform(date = Date.current.to_s)
    DigestInitiatorService.call(date: Date.parse(date), range: Frequency::DAILY)
  end
end
