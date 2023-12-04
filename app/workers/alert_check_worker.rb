class AlertCheckWorker < ApplicationWorker
  include SearchAlertList

  def perform(document_type)
    content_items = get_alert_content_items(document_type:)
    delivered = 0
    content_items.each do |ci|
      if any_emails_delivered_for?(ci[:content_id], ci[:valid_from])
        delivered += 1
      else
        Rails.logger.warn("Couldn't find any delivered emails for #{document_type.titleize} records with content id #{ci[:content_id]} (at #{ci[:url]})")
      end
    end

    Rails.logger.info("Checking #{document_type.titleize} records: #{delivered} out of #{content_items.count} alerts have been delivered to at least one recipient")

    Rails.cache.write("current_#{document_type}s", content_items.count, expires_in: 15.minutes)
    Rails.cache.write("delivered_#{document_type}s", delivered, expires_in: 15.minutes)
  end

  def any_emails_delivered_for?(content_id, valid_from)
    Email.where("notify_status = 'delivered' AND content_id = ? AND created_at > ?", content_id, valid_from).exists?
  end
end
