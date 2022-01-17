class AddOmitFooterUnsubscribeLinkToMessages < ActiveRecord::Migration[6.1]
  def change
    add_column :messages, :omit_footer_unsubscribe_link, :boolean, default: false, null: false
  end
end
