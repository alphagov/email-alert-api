require "csv"

class FakeData
  def self.insert
    new.insert
  end

  def self.delete
    new.delete
  end

  def insert; end

  def delete; end

private

  SubscriptionStat = Struct.new(:number, :count)

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

  def subscriber_addresses

  end

  def no_subscribers
    @no_subscribers ||= subscriptions.map { |s| s.count }.sum
  end

  def subscriptions
    @subscriptions ||= begin
      CSV.read(fake_subscription_data_path).map do |(number, count)|
        SubscriptionStat.new(number.to_i, count.to_i)
      end
    end
  end

  def fake_subscription_data_path
    File.join(File.dirname(__FILE__), "fake_subscription_data.csv")
  end
end
