class EmailGenerationWorker
  include Sidekiq::Worker

  def perform
    EmailGenerationService.call
  end
end
