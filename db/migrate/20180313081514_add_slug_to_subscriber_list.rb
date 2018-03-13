class AddSlugToSubscriberList < ActiveRecord::Migration[5.1]
  def change
    add_column :subscriber_lists, :slug, :string, limit: 1000
  end
end
