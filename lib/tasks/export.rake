namespace :export do
  desc "Export the number of subscribers for a collection of lists as a csv, accepts multiple arguments"
  task :csv, [:subscriber_list_id] => :environment do |_, args|
    DataExporter.new.export_csv(args.to_a)
  end

  desc "Export the number of subscribers for a list"
  task :count, [:subscriber_list_id] => :environment do |_, args|
    list = DataExporter.new.present_subscriber_list(args[:subscriber_list_id])
    puts list[:count] unless list.nil?
  end
end
