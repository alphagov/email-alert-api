require 'csv'

namespace :subscriber_list do
  task export: :environment do
    links_keys = [
      :service_manual_topics,
      :countries,
      :topics,
      :organisations,
      :policies,
      :taxon_tree,
      :policy_areas,
      :world_locations,
      :people,
      :roles,
      :topical_events,
      :parent
    ]

    CSV.open('subscriber_list.csv', 'w') do | csv |
      csv << %w(id title gov_delivery_id enabled subscriber_count) + links_keys.map(&:to_s)
      SubscriberList.all.each do |list|
        print "."
        row = [
          list.id,
          list.title,
          list.gov_delivery_id,
          list.enabled,
          list.subscriber_count,
        ]
        row += links_keys.map { |key| Array(list.links[key]).join(",") }
        csv << row
      end
    end
  end
end
