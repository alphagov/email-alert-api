class MakeSubscriberListTitleNotNull < ActiveRecord::Migration[5.1]
  def change
    change_column_null :subscriber_lists, :title, false
  end
end
