class SubscriberDeactivationWorker
  include Sidekiq::Worker

  sidekiq_options retry: 3

  def perform(subscriber_ids)
    subscriber_ids.each do |subscriber_id|
      subscriber = Subscriber.find(subscriber_id)

      next if subscriber.deactivated? ||
        subscriber.active_subscriptions.exists?

      deactivated_at = subscriber
                         .ended_subscriptions
                         .order(:ended_at)
                         .pluck(:ended_at)
                         .last

      subscriber.deactivate!(datetime: deactivated_at)
    end
  end
end
