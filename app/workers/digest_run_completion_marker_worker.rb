class DigestRunCompletionMarkerWorker
  include Sidekiq::Worker

  def perform(*_ignore)
    DigestRun.incomplete.each(&:check_and_mark_complete!)
  end
end
