class AddSuccessesAndFailuresToSubscribers < ActiveRecord::Migration[6.0]
  change_table :subscribers, bulk: true do |t|
    t.integer :successes, default: 0
    t.integer :failures, default: 0
  end
end
