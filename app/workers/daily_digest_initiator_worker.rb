class DailyDigestInitiatorWorker
  include Sidekiq::Worker

  def perform
    DailyDigestSchedulerService.call
  end
end
