class CreateMatchedMessages < ActiveRecord::Migration[5.2]
  def change
    create_table :matched_messages do |t|
      t.references :message, null: false, type: :uuid, foreign_key: { on_delete: :cascade }
      t.references :subscriber_list, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps

      t.index %i(message_id subscriber_list_id), unique: true
    end
  end
end
