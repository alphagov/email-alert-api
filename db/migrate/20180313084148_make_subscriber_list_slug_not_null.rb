class MakeSubscriberListSlugNotNull < ActiveRecord::Migration[5.1]
  def change
    change_column_null :subscriber_lists, :slug, false
  end
end
