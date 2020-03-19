class AddSuccessesAndFailuresToSubscribers < ActiveRecord::Migration[6.0]
  def change
    add_column :subscribers, :successes, :integer, :default =>0
    add_column :subscribers, :failures, :integer, :default =>0
  end
end
