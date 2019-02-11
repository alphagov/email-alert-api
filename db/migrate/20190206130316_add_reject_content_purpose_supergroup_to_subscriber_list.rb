class AddRejectContentPurposeSupergroupToSubscriberList < ActiveRecord::Migration[5.2]
  def change
    add_column :subscriber_lists, :reject_content_purpose_supergroup, :string, limit: 100
  end
end
