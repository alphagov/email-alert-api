namespace :export do
  desc "Export the number of subscriptions for a collection of lists given as arguments of list IDs"
  task csv_from_ids: :environment do |_, args|
    DataExporter.new.export_csv_from_ids(args.to_a)
  end

  desc "Export the number of subscriptions for a collection of lists given as arguments of list IDs at a given date"
  task :csv_from_ids_at, [:date] => :environment do |_, args|
    DataExporter.new.export_csv_from_ids_at(args.date, args.extras)
  end

  desc "Export the number of subscriptions for the 'Living in' taxons for European countries"
  task csv_from_living_in_europe: :environment do
    DataExporter.new.export_csv_from_living_in_europe
  end

  desc "Export the number of subscriptions for the given subscription list slug(s). eg. rake csv_from_slugs['foo bar baz']"
  task :csv_from_slugs, [:slugs] => :environment do |_, args|
    DataExporter.new.export_csv_from_slugs(args.slugs.split)
  end
end
