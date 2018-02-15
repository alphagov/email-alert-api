task :import_govdelivery_csv, %i(subscriptions_csv_path digests_csv_path) => :environment do |_, args|
  raise "Missing subscriptions CSV path." if args[:subscriptions_csv_path].nil?
  raise "Missing digests CSV path." if args[:digests_csv_path].nil?

  ImportGovdeliveryCsv.call(args[:subscriptions_csv_path], args[:digests_csv_path])
end
