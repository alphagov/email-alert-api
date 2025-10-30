require "csv"

namespace :subscriber_title_update do
  desc "Update the subscriber list title to Palestine for Occupied palestinian territories"
  task replace_occupied_palestinian_titles: :environment do
    results = []

    SubscriberList.where("title ILIKE ?", "%Occupied Palestinian Territories%").find_each do |list|
      new_title = list.title.gsub!(/The Occupied Palestinian Territories|Occupied Palestinian Territories/i, "Palestine")

      next if new_title.nil?

      list.save!
      results << [list.id, list.title]
    end

    csv_output = CSV.generate do |csv|
      csv << %w[id new_title]
      results.each { |id, new_title| csv << [id, new_title] }
    end

    puts csv_output
    puts "Updated #{results.size} SubscriberList titles with Palestine."
  end
end
