class LegacyConversionService
  def self.call
    SubscriberList.all.each do |subscriber_list|
      subscriber_list.update_attribute(:tags, subscriber_list.tags)
      subscriber_list.update_attribute(:links, subscriber_list.links)
    end
  end

  def self.uncall
    SubscriberList.all.each do |subscriber_list|
      subscriber_list['tags'].transform_values! do |tag|
        tag.is_a?(Array) ? tag : tag.fetch('any', [])
      end
      subscriber_list['links'].transform_values! do |tag|
        tag.is_a?(Array) ? tag : tag.fetch('any', [])
      end
      subscriber_list.save!(validate: false)
    end
  end
end
