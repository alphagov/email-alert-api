require 'csv'

class SeedPolicySubscriptions < ActiveRecord::Migration
  def change
    slug_mapping = {}
    mapping_csv_path = File.join(File.dirname(__FILE__), "20150428072646_seed_policy_subscriptions_mapping.csv")
    CSV.foreach(mapping_csv_path, headers: true) do |mapping|
      slug_mapping[mapping["old_slug"]] = mapping["new_slug"]
    end

    csv_path = File.join(File.dirname(__FILE__), "20150428072646_seed_policy_subscriptions.csv")

    CSV.foreach(csv_path) do |(slug, gov_delivery_id)|
      old_slug = slug.gsub(%r{^/}, '')

      if new_slug = slug_mapping[old_slug]
        SubscriberList.create!(
          gov_delivery_id: gov_delivery_id,
          tags: {
            policies: [new_slug]
          },
        )
      else
        puts "No mapping to create subscription for #{old_slug}"
      end
    end
  end
end
