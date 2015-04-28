require 'csv'

class SeedPolicySubscriptions < ActiveRecord::Migration
  def change
    csv_path = File.join(File.dirname(__FILE__), "20150428072646_seed_policy_subscriptions.csv")

    CSV.foreach(csv_path) do |(slug, gov_delivery_id)|
      slug = slug.gsub(%r{^/}, '')

      SubscriberList.create!(
        gov_delivery_id: gov_delivery_id,
        tags: {
          policies: [slug]
        },
      )
    end
  end
end
