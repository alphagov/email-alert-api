require 'json'

class NotificationWorker
  include Sidekiq::Worker

  def perform(notification_json, query_field)
    notification = JSON.parse(notification_json).with_indifferent_access
    links_hash = notification[query_field]

    lists = SubscriberListQuery.new(query_field: query_field)
      .where_all_links_match_at_least_one_value_in(links_hash)

    if lists.any?
      Rails.logger.info "--- Sending email to GovDelivery ---"
      Rails.logger.info "subject: '#{notification[:subject]}'"
      Rails.logger.info "links: '#{links_hash}'"
      Rails.logger.info "matched #{lists.count} lists in GovDelivery: [#{lists.map(&:gov_delivery_id).join(', ')}]"
      Rails.logger.info "notification_json: #{notification_json}"
      Rails.logger.info "--- End email to GovDelivery ---"

      options = notification.slice(:from_address_id, :urgent, :header, :footer)

      Services.gov_delivery.send_bulletin(
        lists.map(&:gov_delivery_id).uniq,
        notification[:subject],
        notification[:body],
        options
      )
      Rails.logger.info "Email '#{notification[:subject]}' sent"
    else
      Rails.logger.info "No matching lists in GovDelivery, not sending email. subject: '#{notification[:subject]}', links: '#{links_hash}'"
    end
  end
end
