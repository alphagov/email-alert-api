Sequel.migration do
  change do
    create_table(:topics) do
      String   :id, text: true
      String   :title, text: true
      String   :subscription_url, text: true

      DateTime :created_at
    end

    add_column :topics, :tags, :hstore
  end
end
