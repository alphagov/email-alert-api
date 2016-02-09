class NotificationWorker
  include Sidekiq::Worker

  def perform(notification_params)
    # FIXME:
    # tl;dr - remove the check on String below after 15th Nov 2015.
    #
    # The parameter to this worker was previously being encoded as JSON at the
    # point of being enqueued (in NotificationsController). Sidekiq was calling
    # JSON.dump on this, resulting in worker args that were JSON encoded twice.
    # When this worker was changed to expect notification_params to be a simple
    # Ruby hash (after being deserialized by Sidekiq), it began breaking in
    # production due to old, previously-failing jobs re-trying one of their 25,
    # exponentially backed off retries. The check below ensures that
    # notification_params are correctly handled, irrespective of whether they
    # were passed in already-encoded or not. This is a bandaid which should be
    # removed after an appropriate length of time - 15th Nov 2015 should be
    # sufficient.
    notification_params = if notification_params.is_a?(String)
                            JSON.parse(notification_params).with_indifferent_access
                          else
                            notification_params.with_indifferent_access
                          end

    @tags_hash  = Hash(notification_params[:tags])
    @links_hash = Hash(notification_params[:links])
    @document_type = notification_params[:document_type]
    delivery_ids = lists.map(&:gov_delivery_id)

    if lists.any?
      Rails.logger.info "--- Sending email to GovDelivery ---"
      Rails.logger.info "subject: '#{notification_params[:subject]}'"
      Rails.logger.info "links: '#{@links_hash}'"
      Rails.logger.info "tags: '#{@tags_hash}'"
      Rails.logger.info "matched #{lists.count} lists in GovDelivery: [#{delivery_ids.join(', ')}]"
      Rails.logger.info "notification_json: #{notification_params.to_json}"
      Rails.logger.info "--- End email to GovDelivery ---"

      options = notification_params.slice(:from_address_id, :urgent, :header, :footer)
      Services.gov_delivery.send_bulletin(
        delivery_ids.uniq,
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
  def lists_matched_on_tags
    @lists_matched_on_tags ||= SubscriberListQuery.new(query_field: :tags)
      .where_all_links_match_at_least_one_value_in(@tags_hash)
  end

  def lists_matched_on_links
    @lists_matched_on_links ||= SubscriberListQuery.new(query_field: :links)
      .where_all_links_match_at_least_one_value_in(@links_hash)
  end

  def filter_by_document_type(matching_lists)
    matching_lists.select { |l| l.document_type.blank? || l.document_type == @document_type }
  end

  def matching_lists
    (lists_matched_on_links + lists_matched_on_tags).uniq { |l| l.id }
  end

  def lists
    @lists ||= filter_by_document_type(matching_lists)
  end
end
