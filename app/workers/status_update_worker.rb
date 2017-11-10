class StatusUpdateWorker
  include Sidekiq::Worker

  def perform(params)
    params.deep_symbolize_keys!

    reference = params.fetch(:reference)
    status = params.fetch(:status).underscore

    attempt = DeliveryAttempt.find_by!(reference: reference)
    attempt.status = status
    attempt.save!
  end
end
