namespace :export do
  desc "Export the number of subscriptions for a collection of lists as a csv, accepts multiple arguments"
  task :csv_from_ids, [] => :environment do |_, args|
    DataExporter.new.export_csv_from_ids(args.to_a)
  end

  desc "Export the number of subscriptions for the 'Living in' taxons for EU countries"
  task :csv_from_living_in_eu, [] => :environment do |_, args|
    DataExporter.new.export_csv_from_living_in_eu
  end

  desc "Export the number of subscriptions for a list"
  task :count, [:subscriber_list_id] => :environment do |_, args|
    puts SubscriberList.find(args[:subscriber_list_id]).active_subscriptions_count
  end
end
