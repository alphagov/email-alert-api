class DigestRunCompletionMarkerWorker
  include Sidekiq::Worker

  def perform(*_)
    DigestRun.incomplete.each(&:check_and_mark_complete!)
  end
end
