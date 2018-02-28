class MakeVariousPrimaryKeyUuiDs < ActiveRecord::Migration[5.1]
  def make_id_uuid(table)
    remove_column table, :id
    add_column table, :id, :uuid, default: "uuid_generate_v4()", primary_key: true
  end

  def remove_int_ids(column, from:)
    from.each do |table|
      remove_column table, column
    end
  end

  def add_uuid_reference(source_table, target_table, index: true, null: false, on_delete: :restrict)
    add_reference source_table, target_table, type: :uuid, index: index, null: null
    add_foreign_key source_table.to_s.pluralize.to_sym, target_table.to_s.pluralize.to_sym, on_delete: on_delete
  end

  def up
    enable_extension "uuid-ossp"

    execute "TRUNCATE emails, content_changes, subscriptions CASCADE"

    make_id_uuid :delivery_attempts

    remove_int_ids :email_id, from: %w(delivery_attempts subscription_contents)
    make_id_uuid :emails
    add_uuid_reference :delivery_attempts, :email, on_delete: :cascade
    add_uuid_reference :subscription_contents, :email, null: true, on_delete: :nullify
    add_index :delivery_attempts, %w(email_id updated_at)

    remove_column :subscription_contents, :subscription_id
    make_id_uuid :subscriptions
    add_uuid_reference :subscription_contents, :subscription, null: true, on_delete: :nullify

    remove_int_ids :content_change_id, from: %w(subscription_contents matched_content_changes)
    make_id_uuid :content_changes
    add_uuid_reference :subscription_contents, :content_change
    add_uuid_reference :matched_content_changes, :content_change
    add_index :matched_content_changes, %w(content_change_id subscriber_list_id), unique: true, name: "index_matched_content_changes_content_change_subscriber_list"
  end
end
