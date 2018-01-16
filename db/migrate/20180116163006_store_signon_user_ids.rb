class StoreSignonUserIds < ActiveRecord::Migration[5.1]
  def change
    add_column :content_changes,    :signon_user_uid, :string
    add_column :subscriber_lists,   :signon_user_uid, :string
    add_column :subscriptions,      :signon_user_uid, :string
    add_column :subscribers,        :signon_user_uid, :string
    add_column :delivery_attempts,  :signon_user_uid, :string
  end
end
