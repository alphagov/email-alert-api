class AddSupertypeFields < ActiveRecord::Migration
  def change
    add_column :subscriber_lists, :email_document_supertype, :string, default: '', null: false
    add_column :subscriber_lists, :government_document_supertype, :string, default: '', null: false
    add_column :notification_logs, :email_document_supertype, :string, default: ''
    add_column :notification_logs, :government_document_supertype, :string, default: ''
  end
end
