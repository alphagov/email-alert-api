namespace :eu_exit_business_finder do
  task update_subscriber_list_titles_and_facet_values: [:environment] do
    subscriber_lists = SubscriberList
      .where("links::text != '{}'")
      .where("ARRAY(SELECT json_object_keys(links)) <@ Array[:keys]", keys: [:facet_values])
    update_facet_values(subscriber_lists)
  end

  # Iterate through the affected subscriber lists and if we encounter any
  # facet values that need replacing with a newer one, we insert the new one
  # to the array (inserted 'in place' to retain original order). Then remove
  # the old facet values in bulk and write only the unique values that remain.
  def update_facet_values(subscriber_lists)
    subscriber_lists.each do |list|
      links = list.links[:facet_values][:any]
      updated_links = links.map { |original_value|
        EuExitFacetMigrationConfig::facet_values_to_replace[original_value] || original_value
      }.flatten
      updated_links = (updated_links - EuExitFacetMigrationConfig::facet_values_to_remove).uniq
      list.write_attribute("links", facet_values: { any: updated_links })
      list.write_attribute("title", title_from_facets(updated_links))
      list.save
    end
  end

  def title_from_facets(facet_values)
    subscription_title_prefix = "EU Exit guidance for your business in the following #{'category'.pluralize(facet_values.count)}: "
    titles = facet_values.map do |facet_value|
      if EuExitFacetMigrationConfig.facet_value_label_overrides[facet_value].present?
        "'#{EuExitFacetMigrationConfig.facet_value_label_overrides[facet_value]}'"
      else
        content_item_title = GdsApi.publishing_api_v2.get_content(facet_value).to_h["title"]
        "'#{content_item_title}'"
      end
    end
    subscription_title_prefix + titles.join(", ")
  end
end

module EuExitFacetMigrationConfig
  def self.facet_values_to_replace
    {
      "9f3476e1-8ff0-455d-a14e-003236b2797c" => %w[53f9ce4c-7cbb-447f-bdf1-a9b022896d3a],
      "b4e507df-f067-4749-9468-3de120775216" => %w[24fd50fa-6619-46ca-96cd-8ce90fa076ce],
      "356f46a0-17d3-4ba4-8952-8c02244f904" => %w[18c3892e-8a0e-4884-906e-5938380eceee],
      "356f46a0-17d3-4ba4-8952-8c02244f9045" => %w[18c3892e-8a0e-4884-906e-5938380eceee],
      # "34a6edd0-46ea-4a76-ae80-8c96709d4f5" is worth noting as
      # it's the result of a merge between two facets. The
      # find-and-replace works the same way regardless.
      "1e3e8abd-135d-4844-afa8-5c51df3d3c57" => %w[34a6edd0-46ea-4a76-ae80-8c96709d4f59],
      "c1d8057c-76bf-431c-9ac8-6281a4b7b9ca" => %w[34a6edd0-46ea-4a76-ae80-8c96709d4f59],
      # "94b3cfe2-af89-4744-b8d7-7fc79edcbc85" is a special case
      # as it's been split into two facets. We should assume the
      # user wants to remain subscribed to both.
      "94b3cfe2-af89-4744-b8d7-7fc79edcbc85" => %w[
        9d54c591-f5ca-4d0c-a484-12d5591987cb
        afd45eef-743a-417d-9245-3eab8322116d
      ],
      # to fix a missing character issue introduced in
      # https://github.com/alphagov/search-api/commit/8fce3db218821dfc7a2b50dbd1b03984b1ec41b1
      "7620da7a-0427-4b3c-9498-db9dc25209b" => %w[7620da7a-0427-4b3c-9498-db9dc25209b0],
    }
  end

  def self.facet_values_to_remove
    %w[
      7536c0c4-fb41-43f4-a2c4-08f4fa9f5427
      5faa1741-fc55-4110-b342-de92f6324118
      14cf2a68-3297-44d3-ba01-a4426845b1b8
      040649fc-4e2c-4028-b846-77fe3eebd1f7
      94b3cfe2-af89-4744-b8d7-7fc79edcbc85
    ]
  end

  def self.facet_value_label_overrides
    {
      "5476f0c7-d029-459b-8a17-196374ae3366" => "Employing EU citizens",
      "bbdbda71-b1ec-46b8-a5b8-931d933288e9" => "Employing non-EU citizens",
      "f165dc7c-7cef-446a-bdfd-8a1ca685d091" => "Public sector procurement - civil government contracts",
      "33fc20d7-6a45-40c9-b31f-e4678f962ff1" => "Public sector procurement - defence contracts",
    }
  end
end
