class NotificationWorker
  include Sidekiq::Worker

  def perform(notification_params)
    notification_params = notification_params.with_indifferent_access

    tags_hash  = Hash(notification_params[:tags])
    links_hash = Hash(notification_params[:links])
    document_type = notification_params[:document_type]

    query = SubscriberListQuery.new(
      tags_hash,
      links_hash,
      document_type,
    )

    enabled_lists, disabled_lists = query.lists.partition(&:enabled?)
    enabled_gov_delivery_ids = enabled_lists.map(&:gov_delivery_id)

    log_notification(
      notification_params,
      enabled_gov_delivery_ids: enabled_gov_delivery_ids,
      disabled_gov_delivery_ids: disabled_lists.map(&:gov_delivery_id),
      tags_hash: tags_hash,
      links_hash: links_hash,
      document_type: document_type,
    )

    if enabled_lists.any?
      Rails.logger.info "--- Sending email to GovDelivery ---"
      Rails.logger.info "subject: '#{notification_params[:subject]}'"
      Rails.logger.info "links: '#{links_hash}'"
      Rails.logger.info "tags: '#{tags_hash}'"
      Rails.logger.info "matched #{enabled_lists.count} lists in GovDelivery: [#{enabled_gov_delivery_ids.join(', ')}]"
      Rails.logger.info "notification_json: #{notification_params.to_json}"
      Rails.logger.info "--- End email to GovDelivery ---"

      send_email(enabled_gov_delivery_ids.uniq, notification_params)
    else
      Rails.logger.info <<-LOG.strip_heredoc
        No matching lists in GovDelivery, not sending email.
          subject: '#{notification_params[:subject]}',
          links: '#{links_hash}',
          tags: #{tags_hash}
      LOG
    end
  end

private

  def send_email(gov_delivery_ids, params)
    Services.gov_delivery.send_bulletin(
      gov_delivery_ids,
      params[:subject],
      params[:body],
      params.slice(:from_address_id, :urgent, :header, :footer)
    )
    Rails.logger.info "Email '#{params[:subject]}' sent"
  rescue GovDelivery::Client::UnknownError => e
    # We want to to be notified when trying to send to a topic without
    # any subscribers (GD-12004), however we want to swallow the error
    # as otherwise the sidekiq job continue to retry, with the same error.
    if e.message =~ /GD-12004/
      Airbrake.notify(e)
    else
      raise
    end
  end

  def log_notification(notification_params, enabled_gov_delivery_ids:, disabled_gov_delivery_ids:, links_hash:, tags_hash:, document_type:)
    NotificationLog.create(
      govuk_request_id: notification_params[:govuk_request_id],
      content_id: notification_params[:content_id],
      public_updated_at: notification_params[:public_updated_at],
      links: links_hash,
      tags: tags_hash,
      document_type: document_type,
      emailing_app: 'email_alert_api',
      gov_delivery_ids: enabled_gov_delivery_ids + disabled_gov_delivery_ids,
      enabled_gov_delivery_ids: enabled_gov_delivery_ids,
      disabled_gov_delivery_ids: disabled_gov_delivery_ids,
      publishing_app: notification_params[:publishing_app],
    )
  rescue Exception
    # rescue any exception here as logging should not delay the email process
    # and more importantly should not result in multiple emails being sent.
  end
end
