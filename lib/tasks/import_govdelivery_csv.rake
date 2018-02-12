task import_govdelivery_csv: :environment do
  csv_path = ENV.fetch("CSV_PATH")
  report = ImportGovdeliveryCsv.import(csv_path)

  puts
  puts "Successful rows: #{report.fetch(:success_count)}"
  puts "Failed rows: #{report.fetch(:failed_count)}"

  report.fetch(:failed_rows).each do |failure|
    puts " - #{failure.inspect}"
  end
end
