class CreateSubscriptions < ActiveRecord::Migration[5.1]
  def change
    create_table :subscriptions do |t|
      t.references :subscriber, null: false, foreign_key: { on_delete: :cascade }
      t.references :subscriber_list, null: false, foreign_key: true
      t.timestamps
    end

    add_index :subscriptions, %i(subscriber_id subscriber_list_id), unique: true
  end
end
