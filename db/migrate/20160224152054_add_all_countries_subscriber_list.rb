# rubocop:disable Lint/UnreachableCode

class AddAllCountriesSubscriberList < ActiveRecord::Migration[4.2]
  def change
    return

    SubscriberList.create!(
      gov_delivery_id: "UKGOVUK_391",
      document_type: "travel_advice",
    )
  end
end

# rubocop:enable Lint/UnreachableCode
