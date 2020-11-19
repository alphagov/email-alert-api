require "csv"

class Reports::SubscribersReportByTag
  def call(criteria, path_to_all_brexit_subscribers_csv)
    table = CSV.parse(File.read(path_to_all_brexit_subscribers_csv), headers: true)
    selected = table.select { |row| row["tags"].include?("\"#{criteria}\"") }
    count = selected.map { |row| row["subscribed"].to_i }.sum
    puts "There are #{table.count} brexit related subscriptions"
    puts "#{count} active subscriptions for subscribers with the tag: #{criteria}"
  end
end
