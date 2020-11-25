class RecoverLostJobsWorker < ApplicationWorker
  def perform
    RecoverLostJobsWorker::UnprocessedCheck.new.call
    RecoverLostJobsWorker::MissingDigestRunsCheck.new.call
    RecoverLostJobsWorker::OldPendingEmailsCheck.new.call
  end
end
