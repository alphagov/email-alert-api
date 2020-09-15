class DigestRunCompletionMarkerWorker
  include Sidekiq::Worker

  def perform
    candidates = DigestRun.where.not(processed_at: nil).where(completed_at: nil)
    candidates.find_each do |digest_run|
      unless DigestRunSubscriber.unprocessed.for_run(digest_run.id).exists?
        digest_run.mark_as_completed
      end
    end
  end
end
