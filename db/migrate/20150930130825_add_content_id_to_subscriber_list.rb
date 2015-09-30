class AddContentIdToSubscriberList < ActiveRecord::Migration
  def change
    add_column :subscriber_lists, :content_id, :string
  end
end
