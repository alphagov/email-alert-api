class CreateEmails < ActiveRecord::Migration[5.1]
  def change
    create_table :emails do |t|
      t.string :subject, null: false
      t.text :body, null: false
      t.references :notification, null: false, foreign_key: true
      t.timestamps
    end
  end
end
