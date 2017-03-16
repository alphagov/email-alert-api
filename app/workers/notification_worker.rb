class NotificationWorker
  include Sidekiq::Worker

  def perform(notification_params)
    notification_params = notification_params.with_indifferent_access

    @tags_hash  = Hash(notification_params[:tags])
    @links_hash = Hash(notification_params[:links])
    @document_type = notification_params[:document_type]

    enabled_lists, disabled_lists = lists.partition(&:enabled?)
    enabled_gov_delivery_ids = enabled_lists.map(&:gov_delivery_id)

    log_notification(
      notification_params,
      enabled_gov_delivery_ids: enabled_gov_delivery_ids,
      disabled_gov_delivery_ids: disabled_lists.map(&:gov_delivery_id),
    )

    if enabled_lists.any?
      Rails.logger.info "--- Sending email to GovDelivery ---"
      Rails.logger.info "subject: '#{notification_params[:subject]}'"
      Rails.logger.info "links: '#{@links_hash}'"
      Rails.logger.info "tags: '#{@tags_hash}'"
      Rails.logger.info "matched #{enabled_lists.count} lists in GovDelivery: [#{enabled_gov_delivery_ids.join(', ')}]"
      Rails.logger.info "notification_json: #{notification_params.to_json}"
      Rails.logger.info "--- End email to GovDelivery ---"

      options = notification_params.slice(:from_address_id, :urgent, :header, :footer)
      Services.gov_delivery.send_bulletin(
        enabled_gov_delivery_ids.uniq,
        notification_params[:subject],
        notification_params[:body],
        options
      )
      Rails.logger.info "Email '#{notification_params[:subject]}' sent"
    else
      Rails.logger.info <<-LOG.strip_heredoc
        No matching lists in GovDelivery, not sending email.
          subject: '#{notification_params[:subject]}',
          links: '#{@links_hash}',
          tags: #{@tags_hash}
      LOG
    end
  end

private

  def log_notification(notification_params, enabled_gov_delivery_ids:, disabled_gov_delivery_ids:)
    NotificationLog.create(
      govuk_request_id: notification_params[:govuk_request_id],
      content_id: notification_params[:content_id],
      public_updated_at: notification_params[:public_updated_at],
      links: @links_hash,
      tags: @tags_hash,
      document_type: @document_type,
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

  def lists_matched_on_tags
    @lists_matched_on_tags ||= SubscriberListQuery.new(query_field: :tags)
      .where_all_links_match_at_least_one_value_in(@tags_hash)
  end

  def lists_matched_on_links
    @lists_matched_on_links ||= SubscriberListQuery.new(query_field: :links)
      .where_all_links_match_at_least_one_value_in(@links_hash)
  end

  def lists_matched_on_document_type_only
    @lists_matched_on_document_type_only ||= SubscriberListQuery.new(query_field: :neither)
      .where_only_document_type_matches(@document_type)
  end

  def filter_by_document_type(matching_lists)
    matching_lists.select { |l| l.document_type.blank? || l.document_type == @document_type }
  end

  def matching_lists
    (
      lists_matched_on_links +
      lists_matched_on_tags +
      lists_matched_on_document_type_only
    ).uniq { |l| l.id }
  end

  def lists
    @lists ||= filter_by_document_type(matching_lists)
  end
end
