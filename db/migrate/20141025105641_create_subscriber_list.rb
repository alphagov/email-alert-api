class CreateSubscriberList < ActiveRecord::Migration[4.2]
  def change
    create_table :subscriber_lists, force: true do |t|
      t.string :title, limit: 255
      t.string :gov_delivery_id, limit: 255
      #t.hstore :tags
      t.timestamps
    end

    #add_index :subscriber_lists, :tags, using: :gin
  end
end
