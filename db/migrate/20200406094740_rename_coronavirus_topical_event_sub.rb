class RenameCoronavirusTopicalEventSub < ActiveRecord::Migration[6.0]
  NEW_TITLE = "Coronavirus (COVID-19)".freeze

  def up
    lists = SubscriberList.where("title like ?", "%Coronavirus (COVID-19): UK government response%")
    lists.each do |list|
      print "Rename #{list.title} to"
      list.title = NEW_TITLE
      list.save!
      puts " #{list.title}"
    end
  end
end
