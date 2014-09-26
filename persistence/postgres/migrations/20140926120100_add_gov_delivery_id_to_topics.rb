Sequel.migration do
  change do
    add_column :topics, :gov_delivery_id, String
  end
end
