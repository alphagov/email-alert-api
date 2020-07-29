require "csv"

class Reports::BrexitSubscribersReport
  CSV_HEADERS = %w[title slug tags subscribed unsubscribed immediately daily weekly].freeze
  attr_reader :date

  def self.call(*args)
    new(args).export_csv
  end

  def initialize(date = nil)
    @date = date
  end

  def parsed_date
    unless date.empty?
      @parsed_date ||= Date.parse(date.to_s)
    end
  end

  def brexit_lists
    @brexit_lists ||= SubscriberList.where("subscriber_lists.tags->>'brexit_checklist_criteria' IS NOT NULL")
  end

  def brexit_lists_before_date
    brexit_lists.select { |list| subscribed_to_before_date(list) }
  end

  def subscribed_to_before_date(list)
    subscriptions =
      list.subscribers.select do |subscriber|
        subscriber.created_at <= parsed_date
      end
    subscriptions.any?
  end

  def report_for_list(list, csv)
    csv << [list.title, list.slug, list.tags, list.subscriptions.active.count, list.subscriptions.ended.count, list.subscriptions.active.immediately.count, list.subscriptions.active.daily.count, list.subscriptions.active.weekly.count]
  end

  def file_name
    date_identifier = `date +%d%m%y_%H%M%S`.chomp
    prefix =
      date.empty? ? "brexit_report" : "brexit_report_subs_before_#{parsed_date}"
    "/tmp/#{prefix}_#{date_identifier}.csv"
  end

  def export_csv
    puts "building csv..."
    csv = build_csv
    puts "finished building"
    File.write(file_name, csv)
    puts "Done! It's in #{file_name}"
  end

  def build_csv
    subscriber_lists =
      date.empty? ? brexit_lists : brexit_lists_before_date
    CSV.generate do |csv|
      csv << CSV_HEADERS
      subscriber_lists.each { |list| report_for_list(list, csv) }
    end
  end
end
