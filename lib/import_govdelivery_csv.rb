require "csv"

class ImportGovdeliveryCsv
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
    get_user_confirmation

    import_subscribers
    import_subscriptions
  end

private

  attr_reader :subscriptions_csv_path, :digests_csv_path, :fake_import, :failed_topics

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

  def import_subscribers
    puts "Loading subscribers from file..."

    addresses = CSV
      .foreach(subscriptions_csv_path, headers: true, encoding: "WINDOWS-1252")
      .map { |row| address_from_row(row) }
      .uniq

    existing_addresses = Subscriber.where(address: addresses).pluck(:address)

    puts "Identifying new subscribers..."

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

  def import_subscriptions
    puts "Loading new subscriptions from file..."

    records = CSV
      .foreach(subscriptions_csv_path, headers: true, encoding: "WINDOWS-1252")
      .with_index(1).map do |row, i|
        puts "Processed #{i} records" if (i % 10000).zero?

        subscriber = subscriber_for_row(row)
        subscribable = subscribable_for_row(row)

        next unless subscribable

        frequency = digest_frequencies.fetch(subscriber.address, Frequency::DAILY)

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

    count = Subscription.import!(columns, records).ids.count

    puts "#{count} subscriptions imported!"

    puts "Unable to match #{failed_topics.count} topics:"
    p failed_topics
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
