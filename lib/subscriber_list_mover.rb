class SubscriberListMover
  attr_reader :from_slug, :to_slug

  def initialize(from_slug:, to_slug:)
    @from_slug = from_slug
    @to_slug = to_slug
  end

  def call
    source_subscriber_list = SubscriberList.find_by(slug: from_slug)
    raise "Source subscriber list #{from_slug} does not exist" if source_subscriber_list.nil?

    source_subscriptions = Subscription.active.find_by(subscriber_list_id: source_subscriber_list.id)
    raise "No active subscriptions to move from #{from_slug}" if source_subscriptions.nil?

    destination_subscriber_list = SubscriberList.find_by(slug: to_slug)
    raise "Destination subscriber list #{to_slug} does not exist" if destination_subscriber_list.nil?

    subscribers = source_subscriber_list.subscribers.activated
    puts "#{subscribers.count} active subscribers moving from #{from_slug} to #{to_slug}"

    subscribers.each do |subscriber|
      Subscription.transaction do
        existing_subscription = Subscription.active.find_by(
          subscriber: subscriber,
          subscriber_list: source_subscriber_list,
        )

        next unless existing_subscription

        existing_subscription.end(reason: :subscriber_list_changed)

        subscribed_to_destination_subscriber_list = Subscription.find_by(
          subscriber: subscriber,
          subscriber_list: destination_subscriber_list,
        )

        if subscribed_to_destination_subscriber_list.nil?
          Subscription.create!(
            subscriber: subscriber,
            subscriber_list: destination_subscriber_list,
            frequency: existing_subscription.frequency,
            source: :subscriber_list_changed,
          )
        end
      end
    end

    puts "#{subscribers.count} active subscribers moved from #{from_slug} to #{to_slug}"
  end
end
