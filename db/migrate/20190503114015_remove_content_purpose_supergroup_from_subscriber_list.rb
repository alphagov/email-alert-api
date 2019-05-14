class RemoveContentPurposeSupergroupFromSubscriberList < ActiveRecord::Migration[5.2]
  def change
    remove_column :subscriber_lists, :content_purpose_supergroup, :string, limit: 100
  end
end
