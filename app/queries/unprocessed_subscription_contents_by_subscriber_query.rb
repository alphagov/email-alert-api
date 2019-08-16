class UnprocessedSubscriptionContentsBySubscriberQuery
  attr_reader :subscriber_ids

  def self.call(*args)
    new(*args).call
  end

  def initialize(subscriber_ids)
    @subscriber_ids = subscriber_ids
  end

  def call
    SubscriptionContent
      .joins(:subscription)
      .includes(:subscription)
      .where(email_id: nil, subscriptions: { subscriber_id: subscriber_ids })
      .group_by { |sc| sc.subscription.subscriber_id }
  end

  private_class_method :new
end
