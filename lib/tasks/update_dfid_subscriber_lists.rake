desc "Update DFID subscriber lists"
task update_dfid_subscriber_lists: :environment do
  # Update all subscriber lists subscribed to dfid_research_output document types
  SubscriberList.where("links->'content_store_document_type'->>'any' LIKE '%dfid_research_output%'").each do |sl|
    new_links = sl.links.merge(
      content_store_document_type: {
        any: (sl.links[:content_store_document_type][:any] - %w[dfid_research_output] + %w[research_for_development_output]),
      },
    )

    sl.update!(links: new_links)
  end

  # Update all subscriber lists subscribed to dfid_research_output document types (no idea what makes these different to the links equivalent)
  SubscriberList.where("tags->'content_store_document_type'->>'any' LIKE '%dfid_research_output%'").each do |sl|
    new_tags = sl.tags.merge(
      content_store_document_type: {
        any: (sl.tags[:content_store_document_type][:any] - %w[dfid_research_output] + %w[research_for_development_output]),
      },
    )

    sl.update!(tags: new_tags)
  end

  # Update subscriber list associated with the dfid_research_output finder
  sl = SubscriberList.find_by("tags->'format'->>'any' LIKE '%dfid_research_output%'")
  new_tags = sl.tags.merge(
    format: {
      any: (sl.tags[:format][:any] - %w[dfid_research_output] + %w[research_for_development_output]),
    },
  )

  sl.update!(tags: new_tags)
end
