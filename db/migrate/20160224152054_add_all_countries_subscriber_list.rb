class AddAllCountriesSubscriberList < ActiveRecord::Migration
  def change
    SubscriberList.create!(
      gov_delivery_id: 'UKGOVUK_391',
      document_type: 'travel_advice'
    )
  end
end
