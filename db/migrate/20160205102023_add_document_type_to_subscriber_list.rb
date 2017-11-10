class AddDocumentTypeToSubscriberList < ActiveRecord::Migration[4.2]
  def change
    add_column :subscriber_lists, :document_type, :string, default: "", null: false
  end
end
