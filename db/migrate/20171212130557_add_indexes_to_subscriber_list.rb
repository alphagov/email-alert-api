class AddIndexesToSubscriberList < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :subscriber_lists, [:document_type], algorithm: :concurrently
    add_index :subscriber_lists, [:email_document_supertype], algorithm: :concurrently
    add_index :subscriber_lists, [:government_document_supertype], algorithm: :concurrently
  end
end
