class CreateSubscriberList < ActiveRecord::Migration
  def change
    create_table :subscriber_lists, force: true do |t|
      t.string :title
      t.string :gov_delivery_id
      t.hstore :tags
      t.timestamps
    end
  end
end
