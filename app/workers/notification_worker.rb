require 'json'

class NotificationWorker
  include Sidekiq::Worker

  def perform(notification_json)
    notification = JSON.parse(notification_json).with_indifferent_access

    lists = SubscriberList.with_at_least_one_tag_of_each_type(tags: notification[:tags])

    EmailAlertAPI.services(:gov_delivery).send_bulletin(
      lists.map(&:gov_delivery_id),
      notification[:subject],
      notification[:body]
    )
  end
end
