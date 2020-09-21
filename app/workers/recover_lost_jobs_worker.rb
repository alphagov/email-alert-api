class RecoverLostJobsWorker
  include Sidekiq::Worker

  def perform
    RecoverLostJobsWorker::UnprocessedCheck.new.call
    RecoverLostJobsWorker::MissingDigestRunsCheck.new.call
  end
end
