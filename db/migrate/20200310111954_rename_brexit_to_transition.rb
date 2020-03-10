class RenameBrexitToTransition < ActiveRecord::Migration[6.0]
  def up
    lists = SubscriberList.where("title like ?", "%Brexit%")
    lists.each do |list|
      print "Rename #{list.title} to"
      list.title.gsub!("Brexit", "Transition")
      list.save!
      puts " #{list.title}"
    end
  end
end
