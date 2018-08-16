class UnsubscribeSubscriberListWorker
  include Sidekiq::Worker

  sidekiq_options retry: 3

  def perform(subscriber_list_id, reason)
    list = SubscriberList.find(subscriber_list_id)
    UnsubscribeService.subscriber_list!(list, reason)
  end
end
