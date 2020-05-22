class RenameCoronavirusTopicalEventSub < ActiveRecord::Migration[6.0]
  NEW_TITLE = "Coronavirus (COVID-19)".freeze

  def up
    lists = SubscriberList.where("title like ?", "%Coronavirus (COVID-19): UK government response%")
    lists.each do |list|
      list.title = NEW_TITLE
      list.save!
    end
  end
end
