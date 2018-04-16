# rubocop:disable Lint/UnreachableCode

require 'csv'

class AddForeignTravelAdviceSubscriberLists < ActiveRecord::Migration[4.2]
  def change
    return

    csv_path = File.join(File.dirname(__FILE__), "20160209143102_add_foreign_travel_advice_subscriber_lists.csv")

    CSV.foreach(csv_path) do |gov_delivery_id, country_slug|
      SubscriberList.create!(
        gov_delivery_id: gov_delivery_id,
        links: {
          countries: [country_slug]
        },
        document_type: 'travel_advice'
      )
      puts "Created subscriber list for #{gov_delivery_id} -> #{country_slug}"
    end
  end
end

# rubocop:enable Lint/UnreachableCode
