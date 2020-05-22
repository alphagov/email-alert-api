class RenameBrexitToTransition < ActiveRecord::Migration[6.0]
  def up
    lists = SubscriberList.where("title like ?", "%Brexit%")
    lists.each do |list|
      list.title.gsub!("Brexit", "Transition")
      list.save!
    end
  end
end
