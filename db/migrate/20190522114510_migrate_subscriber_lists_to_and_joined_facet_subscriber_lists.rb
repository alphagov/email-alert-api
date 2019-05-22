class MigrateSubscriberListsToAndJoinedFacetSubscriberLists < ActiveRecord::Migration[5.2]
  def change
    SubscriberList.where(type: nil).update_all(type: 'AndJoinedFacetSubscriberList')
  end
end
