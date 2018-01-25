class ImmediateEmailGenerationWorker
  include Sidekiq::Worker

  def perform
    ImmediateEmailGenerationService.call
  end
end
