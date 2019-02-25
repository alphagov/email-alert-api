namespace :export do
  desc "Export the number of subscriptions for a collection of lists given as arguments of list IDs"
  task csv_from_ids: :environment do |_, args|
    DataExporter.new.export_csv_from_ids(args.to_a)
  end

  desc "Export the number of subscriptions for a collection of lists given as arguments of list IDs at a given date"
  task :csv_from_ids_at, [:date] => :environment do |_, args|
    DataExporter.new.export_csv_from_ids_at(args.date, args.extras)
  end

  desc "Export the number of subscriptions for a collection of lists given as arguments of list slugs"
  task :csv_from_slugs, [:slugs] => :environment do |_, args|
    DataExporter.new.export_csv_from_slugs(args.slugs.split)
  end

  desc "Export the number of subscriptions for a collection of lists given as arguments of list slugs at a given date"
  task :csv_from_slugs_at, [:date] => :environment do |_, args|
    DataExporter.new.export_csv_from_slugs_at(args.date, args.extras)
  end

  desc "Export the number of subscriptions for the 'Living in' taxons for European countries"
  task csv_from_living_in_europe: :environment do
    DataExporter.new.export_csv_from_living_in_europe
  end

  desc "Export the number of subscriptions for each sector in the Business Readiness finder"
  task csv_from_sectors_in_business_readiness: :environment do
    DataExporter.new.export_csv_from_sectors_in_business_readiness
  end
end
