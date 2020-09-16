class RecoverLostJobsWorker
  include Sidekiq::Worker

  def perform
    RecoverLostJobsWorker::UnprocessedCheck.new.call
    RecoverLostJobsWorker::DigestRunsCheck.new.call
  end
end
