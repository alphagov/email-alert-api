require 'csv'

namespace :manage do
  def unsubscribe(email_address:)
    subscriber = Subscriber.find_by(address: email_address)
    if subscriber.nil?
      puts "Subscriber #{email_address} not found"
    else
      puts "Unsubscribing #{email_address}"
      UnsubscribeService.subscriber!(subscriber, :unsubscribed)
    end
  end

  def move_all_subscribers(from_gov_delivery_id:, to_gov_delivery_id:)
    source_subscriber_list = SubscriberList.find_by(gov_delivery_id: from_gov_delivery_id)
    raise "Source subscriber list #{from_gov_delivery_id} does not exist" if source_subscriber_list.nil?
    source_subscriptions = Subscription.active.find_by(subscriber_list_id: source_subscriber_list.id)
    raise "No active subscriptions to move from #{from_gov_delivery_id}" if source_subscriptions.nil?
    destination_subscriber_list = SubscriberList.find_by(gov_delivery_id: to_gov_delivery_id)
    raise "Destination subscriber list #{to_gov_delivery_id} does not exist" if destination_subscriber_list.nil?
    subscribers = source_subscriber_list.subscribers.activated
    puts "#{subscribers.count} active subscribers moving from #{from_gov_delivery_id} to #{to_gov_delivery_id}"

    subscribers.each do |subscriber|
      Subscription.transaction do
        existing_subscription = Subscription.active.find_by(
          subscriber: subscriber,
          subscriber_list: source_subscriber_list
        )

        existing_subscription.end(reason: :subscriber_list_changed) if existing_subscription

        subscribed_to_destination_subscriber_list = Subscription.find_by(
          subscriber: subscriber,
          subscriber_list: destination_subscriber_list
        )

        if subscribed_to_destination_subscriber_list.nil?
          Subscription.create!(
            subscriber: subscriber,
            subscriber_list: destination_subscriber_list,
            frequency: existing_subscription.frequency,
            source: :subscriber_list_changed
          )
        end
      end
    end

    puts "#{subscribers.count} active subscribers moved from #{from_gov_delivery_id} to #{to_gov_delivery_id}"
  end

  desc "Unsubscribe a single subscriber"
  task :unsubscribe_single, [:email_address] => :environment do |_t, args|
    unsubscribe(email_address: args[:email_address])
  end

  desc "Unsubscribe a list of subscribers from a CSV file"
  task :unsubscribe_bulk_from_csv, [:csv_file_path] => :environment do |_t, args|
    email_addresses = CSV.read(args[:csv_file_path])
    email_addresses.each do |email_address|
      unsubscribe(email_address: email_address[0])
    end
  end

  desc "Move all subscribers from one subscriber list to another"
  task :move_all_subscribers, %i[from_gov_delivery_id to_gov_delivery_id] => :environment do |_t, args|
    move_all_subscribers(from_gov_delivery_id: args[:from_gov_delivery_id], to_gov_delivery_id: args[:to_gov_delivery_id])
  end
end
