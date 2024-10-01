class DigestRunCompletionMarkerJob < ApplicationJob
  def perform
    candidates = DigestRun.where.not(processed_at: nil).where(completed_at: nil)
    candidates.find_each do |digest_run|
      unless DigestRunSubscriber.where(processed_at: nil, digest_run:).exists?
        digest_run.mark_as_completed
      end
    end
  end
end
