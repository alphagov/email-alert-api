class LegacyConversionService
  def self.call
    SubscriberList.all.each do |subscriber_list|
      subscriber_list.update_attribute(:tags, subscriber_list.tags)
      subscriber_list.update_attribute(:links, subscriber_list.links)
    end
  end
end
