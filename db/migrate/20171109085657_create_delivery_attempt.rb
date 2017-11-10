class CreateDeliveryAttempt < ActiveRecord::Migration[5.1]
  def change
    create_table :delivery_attempts do |t|
      t.references :email, null: false, foreign_key: true
      t.integer :status, null: false
      t.integer :provider, null: false
      t.string :reference, null: false
      t.timestamps
    end
  end
end
