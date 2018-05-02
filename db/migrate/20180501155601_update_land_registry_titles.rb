class UpdateLandRegistryTitles < ActiveRecord::Migration[5.2]
  def change
    list = SubscriberList.where("title LIKE '%Land Registry%' AND title NOT LIKE '%HM Land Registry%'")

    list.each do |item|
      item.title.sub! 'Land Registry', 'HM Land Registry'
      item.save!
    end
  end
end
