class UpdateSubscriberCounts
  include Sidekiq::Worker

  def perform
    SubscriberList.find_each do |subscriber_list|
      begin
        topic = Services.gov_delivery.fetch_topic(subscriber_list.gov_delivery_id)
        subscriber_list.update!(subscriber_count: topic["subscribers_count"])
      rescue GovDelivery::Client::UnknownError => e
        Rails.logger.info "Error fetching GovDelivery topic for SubscriberList##{subscriber_list.id}. Error: #{e.inspect}"
      end
    end
  end
end
