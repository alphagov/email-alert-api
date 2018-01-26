class WeeklyDigestInitiatorWorker
  include Sidekiq::Worker

  def perform
    WeeklyDigestSchedulerService.call
  end
end
