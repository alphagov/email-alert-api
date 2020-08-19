class DigestRunCompletionMarkerWorker
  include Sidekiq::Worker

  def perform
    DigestRun.incomplete.find_each do |digest_run|
      unless DigestRunSubscriber.unprocessed_for_run(digest_run.id).exists?
        digest_run.mark_as_completed
      end
    end
  end
end
