require "csv"

class Reports::BrexitSubscribersReport
  CSV_HEADERS = %w[title slug tags subscribed unsubscribed immediately daily weekly]

  def self.call
    new.export_csv
  end

  def brexit_lists
    SubscriberList.where("subscriber_lists.tags->>'brexit_checklist_criteria' IS NOT NULL")
  end

  def report_for_list(list, csv)
    csv << [list.title, list.slug, list.tags, list.subscriptions.active.count, list.subscriptions.ended.count, list.subscriptions.active.immediately.count, list.subscriptions.active.daily.count, list.subscriptions.active.weekly.count]
  end

  def export_csv
    date_identifier = `date +%d%m%y_%H%M%S`.chomp
    file_name = "/tmp/brexit_report_#{date_identifier}.csv"
    puts "building csv..."
    csv = build_csv
    puts "finished building"
    File.write(file_name, csv)
    puts "Done! It's in #{file_name}"
  end

  def build_csv
    CSV.generate { |csv| csv << CSV_HEADERS; brexit_lists.each { |list| report_for_list(list, csv) }}
  end


end
