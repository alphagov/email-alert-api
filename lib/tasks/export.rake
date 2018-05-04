namespace :export do
  desc "Export the number of subscribers for a collection of lists as a csv, accepts multiple arguments"
  task :csv, [:subscriber_list_id] => :environment do |_, args|
    DataExporter.new.export_csv(args.to_a)
  end

  desc "Export the number of subscribers for a list"
  task :count, [:subscriber_list_id] => :environment do |_, args|
    puts SubscriberList.find(args[:subscriber_list_id]).active_subscriptions_count
  end
end
