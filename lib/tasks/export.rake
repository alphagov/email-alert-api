namespace :export do
  desc "Export the number of subscriptions for a collection of lists given as arguments of list IDs"
  task csv_from_ids: :environment do |_, args|
    DataExporter.new.export_csv_from_ids(args.to_a)
  end

  desc "Export the number of subscriptions for the 'Living in' taxons for EU countries"
  task csv_from_living_in_eu: :environment do
    DataExporter.new.export_csv_from_living_in_eu
  end
end
