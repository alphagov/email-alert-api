class MakeSubscriberListSlugUnique < ActiveRecord::Migration[5.1]
  def change
    add_index :subscriber_lists, :slug, unique: true
  end
end
