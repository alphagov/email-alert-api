class AddDeactivatedAtToSubscriber < ActiveRecord::Migration[5.1]
  def change
    add_column :subscribers, :deactivated_at, :datetime
  end
end
