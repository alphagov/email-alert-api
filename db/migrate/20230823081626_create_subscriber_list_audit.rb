class CreateSubscriberListAudit < ActiveRecord::Migration[7.0]
  def change
    create_table :subscriber_list_audits do |t|
      t.references :subscriber_list, null: false, foreign_key: true
      t.integer :reference_count, default: 0

      t.timestamps
    end
  end
end
