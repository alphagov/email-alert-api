class RecoverLostJobsJob < ApplicationJob
  def perform
    RecoverLostJobsJob::UnprocessedCheck.new.call
    RecoverLostJobsJob::MissingDigestRunsCheck.new.call
    RecoverLostJobsJob::OldPendingEmailsCheck.new.call
  end
end
