class StatusUpdateWorker
  include Sidekiq::Worker
  include Sidekiq::Symbols

  def perform(reference:, status:)
    StatusUpdateService.call(reference: reference, status: status)
  end
end
