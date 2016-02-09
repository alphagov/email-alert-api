class AddDocumentTypeToSubscriberList < ActiveRecord::Migration
  def change
    add_column :subscriber_lists, :document_type, :string, default: "", null: false
  end
end
