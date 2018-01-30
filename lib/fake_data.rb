require "csv"

class FakeData
  def self.insert(proportion: 1)
    new.insert(proportion)
  end

  def self.delete
    new.delete
  end

  def insert(proportion)
    if has_test_subscribers?
      raise "There is already test data in the system. Run rake fake_data:delete first."
    end

    fake_subscriptions_data.each do |subscription_stat|
      number_of_subscribers = (subscription_stat.number_of_subscribers * proportion).ceil
      number_of_subscriptions = (subscription_stat.number_of_subscriptions * proportion).ceil

      subscriber_ids = create_subscribers(number_of_subscribers).ids
      create_subscriptions(subscriber_ids, number_of_subscriptions)
    end

    count = existing_test_subscribers.count
    puts "Created #{count} subscribers."
  end

  def delete
    count = existing_test_subscribers.delete_all
    puts "Deleted #{count} subscribers."
  end

private

  def frequencies
    @frequencies ||= begin
      Enumerator.new do |yielder|
        loop do
          3.times { yielder << :weekly }
          7.times { yielder << :daily }
          10.times { yielder << :immediately }
        end
      end
    end
  end

  def subscriber_list_ids
    @subscriber_list_ids ||= begin
      Enumerator.new do |yielder|
        loop do
          SubscriberList.order("RANDOM()").pluck(:id).each do |id|
            yielder << id
          end
        end
      end
    end
  end

  def uuids
    Enumerator.new do |yielder|
      loop { yielder << SecureRandom.uuid }
    end
  end

  def create_subscribers(count)
    puts "Building #{count} subscribers..."

    columns = %i(address)
    records = uuids.take(count).map do |uuid|
      ["success+#{uuid}@simulator.amazonses.com"]
    end

    puts "> Importing #{records.count} subscribers..."

    Subscriber.import!(columns, records, validate: false)
  end

  def create_subscriptions(subscriber_ids, count)
    puts "> Building #{subscriber_ids.count * count} subscriptions..."

    columns = %i(subscriber_id subscriber_list_id frequency uuid)

    count.times do
      records = subscriber_ids.zip(subscriber_list_ids, frequencies, uuids)

      puts ">> Importing #{records.count} subscriptions..."

      Subscription.import!(columns, records, validate: false, on_duplicate_key_ignore: true)
    end
  end

  def existing_test_subscribers
    Subscriber.where("address LIKE 'success+%@simulator.amazonses.com'")
  end

  def has_test_subscribers?
    existing_test_subscribers.exists?
  end

  SubscriptionStat = Struct.new(:number_of_subscriptions, :number_of_subscribers)

  def fake_subscriptions_data
    @fake_subscriptions_data ||= begin
      CSV.read(fake_subscription_data_path).map do |(number_of_subscriptions, number_of_subscribers)|
        SubscriptionStat.new(number_of_subscriptions.to_i, number_of_subscribers.to_i)
      end
    end
  end

  def fake_subscription_data_path
    File.join(File.dirname(__FILE__), "fake_subscription_data.csv")
  end
end
