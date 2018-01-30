require "csv"

class FakeData
  def initialize; end

  def self.call(*args)
    new(*args).call
  end

  def call
    20.times do
      p pick_subscriber_list
    end

    20.times do
      p pick_subscription_frequency
    end

    subscriptions.each do |subscription|
      p subscription
    end
  end

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

  def subscriptions
    @subscriptions ||= begin
      CSV.read(fake_subscription_data_path).map do |(number, count)|
        SubscriptionStat.new(number, count)
      end
    end
  end

  def fake_subscription_data_path
    File.join(File.dirname(__FILE__), "fake_subscription_data.csv")
  end
end
