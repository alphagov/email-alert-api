class NotificationWorker
  include Sidekiq::Worker

  def perform(notification_params)
    # The worker params are a serialized hash, hence the call to JSON.parse
    notification_params = JSON.parse(notification_params).with_indifferent_access

    @tags_hash  = Hash(notification_params[:tags])
    @links_hash = Hash(notification_params[:links])
    lists = (lists_matched_on_links + lists_matched_on_tags).uniq { |l| l.id }
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
end
