# rubocop:disable Lint/UnreachableCode

require 'csv'

class AddContentIDsToTravelAdviceTopics < ActiveRecord::Migration[4.2]
  def change
    return

    csv_path = File.join(File.dirname(__FILE__), "20160215144137_add_content_i_ds_to_travel_advice_topics.csv")

    # Clean up after last migration - delete the erroneous tags
    s = SubscriberList.find_by(gov_delivery_id: "gov_delivery_id")
    s.destroy!
    puts "Destroyed erroneous topic"

    CSV.foreach(csv_path, headers: true, return_headers: false) do |row|
      s = SubscriberList.find_by(gov_delivery_id: row["gov_delivery_id"])
      s.links = {
        countries: [row["content_id"]]
      }
      s.save
      puts "Updated #{row['gov_delivery_id']}"
    end
  end
end
