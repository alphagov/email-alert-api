class FixSubscriberListsWithNoTitles < ActiveRecord::Migration[5.1]
  def up
    return unless Rails.env.production?

    deleted_count = 0
    updated_count = 0

    SubscriberList.where(title: nil).find_each do |subscriber_list|
      begin
        topic = Services.gov_delivery.fetch_topic(subscriber_list.gov_delivery_id)
        subscribers_count = topic.subscribers_count.to_i
      rescue GovDelivery::Client::TopicNotFound
        subscribers_count = 0
      end

      if subscribers_count.zero?
        subscriber_list.destroy
        deleted_count += 1
      else
        subscriber_list.update(title: topic.name)
        updated_count += 1
      end
    end

    puts "Deleted #{deleted_count} subscriber lists."
    puts "Updated #{updated_count} subscriber lists."
  end
end
