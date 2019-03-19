class RemoveRejectContentPurposeSupergroupFromSubscriberList < ActiveRecord::Migration[5.2]
  def change
    remove_column :subscriber_lists, :reject_content_purpose_supergroup, :string
  end
end
