class AddSubscriptionContent < ActiveRecord::Migration[5.1]
  def change
    create_table :subscription_contents do |t|
      t.references :subscription, null: false, foreign_key: true
      t.references :content_change, null: false, foreign_key: true
      t.references :email, null: true, foreign_key: true
      t.timestamps
    end
  end
end
