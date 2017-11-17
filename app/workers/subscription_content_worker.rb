class SubscriptionContentWorker
  include Sidekiq::Worker

  def perform(content_change_id:)
  end

private

end
