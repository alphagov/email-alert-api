class RemoveTitleIndexFromSubscriberList < ActiveRecord::Migration[5.2]
  def change
    remove_index "subscriber_lists", name: "index_subscriber_lists_on_title"
  end
end
