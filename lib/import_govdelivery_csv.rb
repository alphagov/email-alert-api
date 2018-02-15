require "csv"

class ImportGovdeliveryCsv
  def initialize(subscriptions_csv_path, digests_csv_path, fake_import: false)
    @subscriptions_csv_path = subscriptions_csv_path
    @digests_csv_path = digests_csv_path
    @fake_import = fake_import
    @imported_count = 0
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    check_encoding_is_windows_1252
    get_user_confirmation

    CSV.foreach(subscriptions_csv_path, headers: true, encoding: "WINDOWS-1252") do |row|
      import_row(row)
    end

    puts "Imported #{@imported_count} subscriptions."
  end

private

  attr_reader :subscriptions_csv_path, :digests_csv_path, :fake_import

  DEFAULT_DIGEST_FREQUENCY = Frequency::IMMEDIATELY

  def address_from_row(row)
    address = row.fetch("DESTINATION")

    if fake_import
      hashed_address = Digest::SHA1.hexdigest(address)
      "success+#{hashed_address}@simulator.amazonses.com"
    else
      address
    end
  end

  def subscriber_for_row(row)
    Subscriber.find_or_create_by!(address: address_from_row(row))
  end

  def subscribable_for_row(row)
    topic_code = row.fetch("TOPIC_CODE")
    SubscriberList.find_by!(gov_delivery_id: topic_code)
  end

  def import_row(row)
    subscriber = subscriber_for_row(row)
    subscribable = subscribable_for_row(row)
    frequency = digest_frequencies.fetch(subscriber.address, DEFAULT_DIGEST_FREQUENCY)

    validate_name(subscribable, row)

    find_or_create_subscription(subscriber, subscribable, frequency)

    @imported_count += 1
  end

  def validate_name(subscribable, row)
    topic_name = row.fetch("TOPIC_NAME")

    expected = topic_name.strip
    actual = subscribable.title.strip

    raise "Name mismatch: #{expected} != #{actual}" if expected != actual
  end

  def find_or_create_subscription(subscriber, subscribable, frequency)
    subscriber.subscriptions.find_or_create_by!(
      subscriber_list: subscribable,
      frequency: frequency,
    )
  end

  def digest_frequencies
    @digest_frequencies ||= begin
      CSV.foreach(digests_csv_path, headers: true, encoding: "WINDOWS-1252").each_with_object({}) do |row, hash|
        hash[address_from_row(row)] = digest_frequency_for_row(row)
      end
    end
  end

  def digest_frequency_for_row(row)
    digest_for = row.fetch("DIGEST_FOR").to_i

    case digest_for
    when 0
      Frequency::IMMEDIATELY
    when 1
      Frequency::DAILY
    when 7
      Frequency::WEEKLY
    else
      raise "Unknown digest frequency: #{digest_for}"
    end
  end

  def check_encoding_is_windows_1252
    File.readlines(subscriptions_csv_path).each do |line|
      if line.include?("Principe") && !line.include?("São Tomé and Principe")
        message = "The CSV has the wrong encoding. It should be WINDOWS-1252."
        message += "\nYou can set the encoding in LibreOffice with:"
        message += "\nFile > Save As > Edit filter settings > Character set > Western Europe (Windows-1252/WinLatin 1)"

        raise EncodingError, message
      end
    end
  end

  def get_user_confirmation
    puts "You are about to import the following data:"
    puts " > Subscriptions from #{subscriptions_csv_path}"
    puts " > Digests from #{digests_csv_path}"

    if fake_import
      puts " > The email addresses will be anonymised."
    else
      puts " > This is a real import. The email addresses will NOT be anonymised."
    end

    puts
    puts "Continue? (Press Ctrl+C to cancel)"

    $stdin.gets
  end
end
