Sequel.migration do
  change do
    rename_table("topics", "subscriber_lists")
  end
end
