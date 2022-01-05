class UseTextForLongSubscriberListsColumns < ActiveRecord::Migration[6.1]
  def up
    change_table :subscriber_lists, bulk: true do |t|
      t.change :title, :text
      t.change :url, :text
    end
  end

  def down
    change_table :subscriber_lists, bulk: true do |t|
      t.change :title, :string
      t.change :url, :string
    end
  end
end
