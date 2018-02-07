require "csv"

class ImportGovdeliveryCsv
  def self.import(*args)
    new(*args).import
  end

  attr_reader :csv_path, :digest_csv_path, :output_io

  def initialize(csv_path, digest_csv_path, output_io: nil)
    @csv_path = csv_path
    @digest_csv_path = digest_csv_path
    @output_io = output_io
  end

  def import
    check_encoding_is_windows_1252

    CSV.foreach(csv_path, headers: true, encoding: "WINDOWS-1252") do |row|
      with_reporting(row) { import_row(row) }
    end

    build_report
  end

  def import_row(row)
    subscriber = find_or_create_subscriber(row)
    subscribable = find_subscribable(row)
    frequency = digest_data.fetch(subscriber.address)

    validate_name(subscribable, row)

    find_or_create_subscription(subscriber, subscribable, frequency)
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

  def digest_data
    @digest_data ||= begin
      CSV.foreach(digest_csv_path, headers: true, encoding: "WINDOWS-1252").each_with_object({}) do |row, hash|
        hash[row.fetch("DESTINATION")] = digest_frequency_for_row(row.fetch("DIGEST_FOR"))
      end
    end
  end

  def digest_frequency_for_row(frequency)
    case frequency.to_i
    when 0
      Frequency::IMMEDIATELY
    when 1
      Frequency::DAILY
    when 7
      Frequency::WEEKLY
    else
      raise "Unknown digest frequency: #{frequency}"
    end
  end

  def find_or_create_subscription(subscriber, subscribable, frequency)
    subscriber.subscriptions.find_or_create_by!(
      subscriber_list: subscribable,
      frequency: frequency,
    )
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

  def check_encoding_is_windows_1252
    File.readlines(csv_path).each do |line|
      if line.include?("Principe") && !line.include?("São Tomé and Principe")
        message = "The CSV has the wrong encoding. It should be WINDOWS-1252."
        message += "\nYou can set the encoding in LibreOffice with:"
        message += "\nFile > Save As > Edit filter settings > Character set > Western Europe (Windows-1252/WinLatin 1)"

        raise EncodingError, message
      end
    end
  end
end
