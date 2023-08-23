require "content_item_list_query"

class SubscriberListAuditWorker < ApplicationWorker
  sidekiq_options queue: :subscriber_list_audit

  def perform(url_batch)
    content_store_client = GdsApi.content_store

    url_batch.each do |url|
      parsed_url = URI.parse(url)
      begin
        content_item = content_store_client.content_item(parsed_url.path).to_hash

        if EmailAlertCriteria.new(content_item:).would_trigger_alert?
          query = ContentItemListQuery.new(parsed_url.path, false)
          query.lists_by_content_item(content_item).each { |list| SubscriberListAudit.increment_count(list) }
        end
      rescue StandardError
        # We don't really need to do much here, just not crash the worker
      end
    end
  end
end
