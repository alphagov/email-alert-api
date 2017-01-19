class AddShortNameAndDescriptionToSubscriberList < ActiveRecord::Migration
  def change
    add_column :subscriber_lists, :short_name, :string, after: :title
    add_column :subscriber_lists, :description, :string, after: :title
  end
end
