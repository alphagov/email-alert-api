require "csv"

class ImportGovdeliveryCsv
  def self.import(*args)
    new(*args).import
  end

  attr_accessor :csv_path, :output_io

  def initialize(csv_path, output_io = nil)
    self.csv_path = csv_path
    self.output_io = output_io
  end

  def import
    CSV.foreach(csv_path, headers: true) do |row|
      with_reporting(row) { import_row(row) }
    end

    build_report
  end

  def import_row(row)
    subscriber = find_or_create_subscriber(row)
    subscribable = find_subscribable(row)

    validate_name(subscribable, row)

    find_or_create_subscription(subscriber, subscribable)
  end

  def find_or_create_subscriber(row)
    destination = row.fetch("DESTINATION")
    Subscriber.find_or_create_by!(address: destination)
  end

  def find_subscribable(row)
    topic_code = row.fetch("TOPIC_CODE")
    SubscriberList.find_by!(gov_delivery_id: topic_code)
  end

  def validate_name(subscribable, row)
    topic_name = row.fetch("TOPIC_NAME")

    expected = topic_name.strip
    actual = subscribable.title.strip

    raise "Name mismatch: #{expected} != #{actual}" if expected != actual
  end

  def find_or_create_subscription(subscriber, subscribable)
    subscriber.subscriptions.find_or_create_by!(subscriber_list: subscribable)
  end

  def with_reporting(row)
    @success_count ||= 0
    @failed_count ||= 0
    @failed_rows ||= []

    begin
      yield
      output(".")
      @success_count += 1
    rescue StandardError => error
      output("F")
      @failed_count += 1
      @failed_rows << [error.message, row.to_h]
    end
  end

  def build_report
    {
      success_count: @success_count,
      failed_count: @failed_count,
      failed_rows: @failed_rows,
    }
  end

  def output(message)
    output_io.print(message) if output_io
  end
end
