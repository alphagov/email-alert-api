require "gds_api/test_helpers/content_store"

module ContentItemHelpers
  include GdsApi::TestHelpers::ContentStore

  def required_match_attributes(tags:)
    {
      "locale" => "en",
      "government_document_supertype" => "email",
      "details" => {
        "tags" => tags,
        "change_history" => [
          { "public_timestamp" => Time.zone.now.to_s, "note" => "changed" },
        ],
      },
    }
  end

  def match_by_tags_content_item_for_subscriber_list(subscriber_list:, tags: { "topics" => ["motoring/road_rage"] }, draft: false)
    content_item = content_item_for_base_path(subscriber_list_path(subscriber_list)).merge(required_match_attributes(tags:))
    stub_content_store_has_item(subscriber_list_path(subscriber_list), content_item, draft:)
  end

  def match_by_tags_non_triggering_content_item_for_subscriber_list(subscriber_list:, tags: { "topics" => ["motoring/road_rage"] })
    merge_items = required_match_attributes(tags:)
    merge_items.delete("locale")
    content_item = content_item_for_base_path(subscriber_list_path(subscriber_list)).merge(merge_items)
    stub_content_store_has_item(subscriber_list_path(subscriber_list), content_item)
  end

  def subscriber_list_path(subscriber_list)
    URI(subscriber_list.url).path
  end
end
