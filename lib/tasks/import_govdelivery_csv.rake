task :import_govdelivery_csv, %i(subscriptions_csv_path digests_csv_path) => :environment do |_, args|
  raise "Missing subscriptions CSV path." if args[:subscriptions_csv_path].nil?
  raise "Missing digests CSV path." if args[:digests_csv_path].nil?

  report = ImportGovdeliveryCsv.call(args[:subscriptions_csv_path], args[:digests_csv_path])

  puts
  puts "Successful rows: #{report.fetch(:success_count)}"
  puts "Failed rows: #{report.fetch(:failed_count)}"

  report.fetch(:failed_rows).each do |failure|
    puts " - #{failure.inspect}"
  end
end
