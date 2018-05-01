require 'csv'

namespace :export do
  def present_subscriber_list(list_id)
    list = SubscriberList.find(list_id)
    { subscriber_list_id: list_id, title: list.title, count: list.subscribers.count }
  rescue ActiveRecord::RecordNotFound
    warn "could not fetch record for #{list_id}"
  end

  desc "Export the number of subscribers for a collection of lists as a csv, accepts multiple arguments"
  task :csv, [:subscriber_list_id] => :environment do |_, args|
    CSV($stdout, headers: %i[subscriber_list_id title count], write_headers: true) do |csv|
      rows = args.to_a.map { |list_id| present_subscriber_list(list_id) }
      rows.compact.each { |row| csv << row }
    end
  end

  desc "Export the number of subscribers for a list"
  task :count, [:subscriber_list_id] => :environment do |_, args|
    list = present_subscriber_list(args[:subscriber_list_id])
    puts list[:count] unless list.nil?
  end
end
