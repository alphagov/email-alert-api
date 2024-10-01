class SubscriberListAuditJob < ApplicationJob
  sidekiq_options queue: :subscriber_list_audit

  def perform(url_batch, audit_start_time_string)
    audit_start_time = Time.zone.parse(audit_start_time_string)
    content_store_client = GdsApi.content_store
    return unless SubscriberList.unaudited_since(audit_start_time).any?

    url_batch.each do |url|
      parsed_url = URI.parse(url)
      govuk_path = parsed_url.path
      begin
        content_item = content_store_client.content_item(govuk_path).to_hash

        if EmailAlertCriteria.new(content_item:).would_trigger_alert?
          lists = SubscriberListsByContentItemQuery.new(content_item).call
          lists.each { |list| list.update_column(:last_audited_at, audit_start_time) }
        end
      rescue StandardError
        # We don't really need to do much here, just not crash the worker
      end
    end
  end
end
