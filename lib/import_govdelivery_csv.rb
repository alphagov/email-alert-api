require "csv"

class ImportGovdeliveryCsv
  include ActionView::Helpers::NumberHelper

  def initialize(subscriptions_csv_path, digests_csv_path, fake_import: false)
    @subscriptions_csv_path = subscriptions_csv_path
    @digests_csv_path = digests_csv_path
    @fake_import = fake_import
    @failed_topics = Set.new
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    check_encoding_is_windows_1252
    sanity_check_csv

    get_user_confirmation

    import_subscribers
    import_subscriptions
  end

private

  attr_reader :subscriptions_csv_path, :digests_csv_path, :fake_import, :failed_topics

  DEFAULT_DIGEST_FREQUENCY = Frequency::IMMEDIATELY

  def sanity_check_csv
    puts "Sanity checking the files..."
    err = []
    subscription_csv_headers = CSV.open(subscriptions_csv_path, 'r').first
    digests_csv_headers = CSV.open(digests_csv_path, 'r').first
    err << "Your subscription csv is incorrect." unless subscription_csv_headers.map(&:downcase).include?("topic_code")
    err << "Your digest csv is incorrect." unless digests_csv_headers.map(&:downcase).include?("digest_for")
    raise err.join(' ') unless err.empty?
  end

  def address_from_row(row)
    address = row.fetch("DESTINATION")

    if fake_import
      hashed_address = Digest::SHA1.hexdigest(address)
      "success+#{hashed_address}@simulator.amazonses.com"
    else
      address
    end
  end

  def import_subscribers
    puts "Loading subscribers from file..."

    addresses = CSV
      .foreach(subscriptions_csv_path, headers: true, encoding: "WINDOWS-1252")
      .map { |row| address_from_row(row) }
      .uniq

    puts "Identifying new subscribers..."

    existing_addresses = Subscriber.where(address: addresses).pluck(:address)

    new_addresses = addresses - existing_addresses

    columns = %w(address)
    records = new_addresses.map { |address| [address] }

    puts "Importing records..."

    count = Subscriber.import!(columns, records).ids.count

    puts "#{count} subscribers imported!"
  end

  def all_subscribers
    @all_subscribers ||= begin
      puts "Loading all subscribers from database..."
      Subscriber.all.index_by(&:address)
    end
  end

  def subscriber_for_row(row)
    address = address_from_row(row)
    all_subscribers.fetch(address)
  end

  def all_subscribables
    @all_subscribables ||= begin
      puts "Loading all subscribables from database..."
      SubscriberList.all.index_by(&:gov_delivery_id)
    end
  end

  def subscribable_for_row(row)
    topic_code = row.fetch("TOPIC_CODE")
    all_subscribables.fetch(topic_code)
  rescue KeyError
    failed_topics.add(topic_code)
    nil
  end

  def frequency_for_subscription(subscribable, subscriber)
    if subscribable.is_travel_advice? || subscribable.is_medical_safety_alert?
      Frequency::IMMEDIATELY
    else
      digest_frequencies.fetch(subscriber.address, Frequency::DAILY)
    end
  end

  def import_subscriptions
    puts "Loading new subscriptions from file..."

    records = CSV
      .foreach(subscriptions_csv_path, headers: true, encoding: "WINDOWS-1252")
      .with_index(1).map do |row, i|
        puts "Processed #{i} records" if (i % 10000).zero?

        subscriber = subscriber_for_row(row)
        subscribable = subscribable_for_row(row)

        next unless subscribable

        frequency = frequency_for_subscription(subscribable, subscriber)

        next if Subscription.where(
          subscriber_id: subscriber.id,
          subscriber_list_id: subscribable.id,
          frequency: frequency
        ).exists?

        [subscriber.id, subscribable.id, frequency, SecureRandom.uuid]
      end

    records = records.compact

    columns = %w(subscriber_id subscriber_list_id frequency uuid)

    puts "Importing records..."

    tally = 0
    total_records = records.length
    start_time = Time.now
    records.each_slice(150000) do |records_chunk|
      count = Subscription.import!(columns, records_chunk).ids.count
      tally += count
      puts "#{number_with_delimiter(tally)}/#{number_with_delimiter(total_records)} subscriptions imported...Time remaining: #{time_remaining(start_time, tally, total_records)}"
    end

    puts "Unable to match #{failed_topics.count} topics:"
    p failed_topics
  end

  def time_remaining(start_time, completed, total)
    seconds_elapsed = Time.now.to_i - start_time.to_i
    per_second = seconds_elapsed.to_f / completed
    remaining_time = per_second * (total - completed)
    # This won't work if it's over 24 hours, but that's probably a bigger problem
    Time.at(remaining_time).utc.strftime("%H:%M:%S")
  end

  def digest_frequencies
    @digest_frequencies ||= begin
      puts "Loading digest frequencies from file..."
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
