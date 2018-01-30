require "csv"

class FakeData
  def self.insert
    new.insert
  end

  def self.delete
    new.delete
  end

  def insert
    if has_test_subscribers?
      raise "There is already test data in the system. Run rake fake_data:delete first."
    end

    fake_subscriptions_data.each do |subscription_stat|
      subscriber_ids = create_subscribers(subscription_stat.count)
    end
  end

  def delete
    count = existing_test_subscribers.delete_all
    puts "Deleted #{count} subscribers."
  end

private

  def pick_subscriber_list(limit: 1)
    SubscriberList.order("RANDOM()").limit(limit)
  end

  def pick_subscription_frequency
    random = Random.new
    choice = random.rand(1.0)

    if choice < 0.15
      :weekly
    elsif choice < 0.5
      :daily
    else
      :immediately
    end
  end

  def create_subscribers(count)
    puts "Creating #{count} subscribers..."

    records = count.times.map do
      { address: "success+#{SecureRandom.uuid}@simulator.amazonses.com" }
    end

    Subscriber.import!(records)
  end

  def existing_test_subscribers
    Subscriber.where("address LIKE 'success+%@simulator.amazonses.com'")
  end

  def has_test_subscribers?
    existing_test_subscribers.exists?
  end

  SubscriptionStat = Struct.new(:number, :count)

  def fake_subscriptions_data
    @fake_subscriptions_data ||= begin
      CSV.read(fake_subscription_data_path).map do |(number, count)|
        SubscriptionStat.new(number.to_i, count.to_i)
      end
    end
  end

  def fake_subscription_data_path
    File.join(File.dirname(__FILE__), "fake_subscription_data.csv")
  end
end
