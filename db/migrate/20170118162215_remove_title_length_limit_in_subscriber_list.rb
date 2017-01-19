class RemoveTitleLengthLimitInSubscriberList < ActiveRecord::Migration
  def up
    change_column :subscriber_lists, :title, :string, limit: nil
  end

  def down
    change_column :subscriber_lists, :title, :string, limit: 255
  end
end
