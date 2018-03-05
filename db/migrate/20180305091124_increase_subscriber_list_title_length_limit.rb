class IncreaseSubscriberListTitleLengthLimit < ActiveRecord::Migration[5.1]
  def up
    change_column :subscriber_lists, :title, :string, limit: 1000
  end
end
