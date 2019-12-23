class SubscribersForImmediateEmailQuery
  def self.call_in_batches(content_change_id: nil, message_id: nil)
    additional_parameters = {
      content_change_id: content_change_id,
      message_id: message_id,
    }.compact

    unprocessed_subscription_content_exists =
      SubscriptionContent
        .joins(:subscription)
        .where({ email_id: nil }.merge(additional_parameters))
        .where("subscriptions.subscriber_id = subscribers.id")
        .arel
        .exists

    Subscriber.in_batches(of: ImmediateEmailGenerationWorker::BATCH_SIZE).each do |relation|
      subscribers = relation.activated.where(unprocessed_subscription_content_exists).
        pluck(:id, :address).
        map { |id_address| { id: id_address.first, address: id_address.second } }
      yield(subscribers)
    end
  end
end
