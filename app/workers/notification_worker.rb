class NotificationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :govdelivery

  def perform(notification_params)
    # This is used to disable sending data to govdelivery while the system
    # transitions from govdelivery to notify.
    #
    # Note this does not store any data and details of any jobs that are
    # disabled will be lost unless we set something up to store them.
    return if ENV.include?("DISABLE_GOVDELIVERY_EMAILS")

    notification_params = notification_params.with_indifferent_access

    tags_hash  = Hash(notification_params[:tags])
    links_hash = Hash(notification_params[:links])

    query = SubscriberListQuery.new(
      tags: tags_hash,
      links: links_hash,
      document_type: notification_params[:document_type],
      email_document_supertype: notification_params[:email_document_supertype],
      government_document_supertype: notification_params[:government_document_supertype],
    )

    gov_delivery_ids = query.lists.map(&:gov_delivery_id)

    log_notification(
      notification_params,
      gov_delivery_ids: gov_delivery_ids,
      tags_hash: tags_hash,
      links_hash: links_hash,
    )

    if gov_delivery_ids.any?
      Rails.logger.info "--- Sending email to GovDelivery ---"
      Rails.logger.info "subject: '#{notification_params[:subject]}'"
      Rails.logger.info "links: '#{links_hash}'"
      Rails.logger.info "tags: '#{tags_hash}'"
      Rails.logger.info "matched #{gov_delivery_ids.count} lists in GovDelivery: [#{gov_delivery_ids.join(', ')}]"
      Rails.logger.info "notification_json: #{notification_params.to_json}"
      Rails.logger.info "--- End email to GovDelivery ---"

      send_email(gov_delivery_ids.uniq, notification_params)
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
    # We don't want to to be notified or retry the job when trying to send to a
    # topic without any subscribers (GD-12004).
    raise unless e.message.match?(/GD-12004/)
  end

  def log_notification(notification_params, gov_delivery_ids:, links_hash:, tags_hash:)
    NotificationLog.create(
      govuk_request_id: notification_params[:govuk_request_id],
      content_id: notification_params[:content_id],
      public_updated_at: notification_params[:public_updated_at],
      links: links_hash,
      tags: tags_hash,
      document_type: notification_params[:document_type],
      email_document_supertype: notification_params[:email_document_supertype],
      government_document_supertype: notification_params[:government_document_supertype],
      gov_delivery_ids: gov_delivery_ids,
      publishing_app: notification_params[:publishing_app],
    )
  rescue Exception # rubocop:disable Lint/RescueException
    # rescue any exception here as logging should not delay the email process
    # and more importantly should not result in multiple emails being sent.
    nil
  end
end
