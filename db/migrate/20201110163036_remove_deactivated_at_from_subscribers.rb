class RemoveDeactivatedAtFromSubscribers < ActiveRecord::Migration[6.0]
  def change
    remove_column :subscribers, :deactivated_at, :datetime
  end
end
