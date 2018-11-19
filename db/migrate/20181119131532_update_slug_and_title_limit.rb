class UpdateSlugAndTitleLimit < ActiveRecord::Migration[5.2]
  def change
    change_column :subscriber_lists, :title, :string, limit: 10000
    change_column :subscriber_lists, :slug, :string, limit: 10000
  end
end
