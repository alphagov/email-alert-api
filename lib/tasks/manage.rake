require 'csv'

namespace :manage do
  def change_email_address(old_email_address:, new_email_address:)
    subscriber = Subscriber.find_by_address(old_email_address)
    raise "Cannot find subscriber with email address #{old_email_address}" if subscriber.nil?

    subscriber.address = new_email_address
    if subscriber.save!
      puts "Changed email address for #{old_email_address} to #{new_email_address}"
    else
      puts "Error changing email address for #{old_email_address} to #{new_email_address}"
    end
  end

  def unsubscribe(email_address:)
    subscriber = Subscriber.find_by(address: email_address)
    if subscriber.nil?
      puts "Subscriber #{email_address} not found"
    else
      puts "Unsubscribing #{email_address}"
      UnsubscribeService.subscriber!(subscriber, :unsubscribed)
    end
  end

  def move_all_subscribers(from_slug:, to_slug:)
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
          subscriber_list: source_subscriber_list
        )

        next unless existing_subscription

        existing_subscription.end(reason: :subscriber_list_changed)

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

    puts "#{subscribers.count} active subscribers moved from #{from_slug} to #{to_slug}"
  end

  def find_subscriber_list_by_title(title:)
    subscriber_lists = SubscriberList.where("title ILIKE ?", "%#{title}%")

    raise "Cannot find any subscriber lists with title containing `#{title}`" if subscriber_lists.nil?

    puts "Found #{subscriber_lists.count} subscriber lists containing '#{title}'"

    subscriber_lists.each do |subscriber_list|
      puts "============================="
      puts "title: #{subscriber_list.title}"
      puts "slug: #{subscriber_list.slug}"
    end
  end

  def update_subscriber_list(slug:, new_title:, new_slug:)
    subscriber_list = SubscriberList.find_by(slug: slug)

    raise "Cannot find subscriber list with #{slug}" if subscriber_list.nil?

    subscriber_list.title = new_title
    subscriber_list.slug = new_slug

    if subscriber_list.save!
      puts "Subscriber list updated with title:#{new_title} and slug: #{new_slug}"
    else
      puts "Error updating subscriber list with title:#{new_title} and slug: #{new_slug}"
    end
  end

  desc "Change the email address of a subscriber"
  task :change_email_address, %i[old_email_address new_email_address] => :environment do |_t, args|
    change_email_address(old_email_address: args[:old_email_address], new_email_address: args[:new_email_address])
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
  task :move_all_subscribers, %i[from_slug to_slug] => :environment do |_t, args|
    move_all_subscribers(from_slug: args[:from_slug], to_slug: args[:to_slug])
  end

  desc "Unsubscribe subscribers using a list policy areas to taxons"
  task :unsubscribe_bulk_policy_areas, %i[subscriber_limit courtesy_emails_every_nth_email people_path world_location_path organisations_path policy_area_mappings_path] => :environment do |_t, args|
    args.with_defaults(
      subscriber_limit: 1_000_000,
      courtesy_emails_every_nth_email: 500,
      people_path: 'tmp/people.json', #[{content_id: ..., slug: ....}]
      world_location_path: 'tmp/world_locations.json', #[{content_id: ..., slug: ....}]
      organisations_path: 'tmp/organisations.json', #[{content_id: ..., slug: ....}]
      policy_area_mappings_path: 'tmp/policy_area_mappings.json' #[{content_id: ..., taxon_path: ...., policy_area_path:}]
    )

    people = JSON.parse(File.read(args[:people_path]), symbolize_names: true)
    world_locations = JSON.parse(File.read(args[:world_location_path]), symbolize_names: true)
    organisations = JSON.parse(File.read(args[:organisations_path]), symbolize_names: true)
    policy_area_mappings = JSON.parse(File.read(args[:policy_area_mappings_path]), symbolize_names: true)

    puts "Processing #{args[:subscriber_limit].to_i} subscribers"
    puts "Sending a courtesy copy every #{args[:courtesy_emails_every_nth_email].to_i} emails"

    BulkUnsubscribeService.call(
      subscriber_limit: args[:subscriber_limit].to_i,
      courtesy_emails_every_nth_email: args[:courtesy_emails_every_nth_email].to_i,
      people: people,
      world_locations: world_locations,
      organisations: organisations,
      policy_area_mappings: policy_area_mappings
    )
  end

  desc "Find subscriber lists by title match"
  task :find_subscriber_list_by_title, %i[title] => :environment do |_t, args|
    find_subscriber_list_by_title(title: args[:title])
  end

  desc "Update subscriber list title and slug"
  task :update_subscriber_list, %i[slug new_title new_slug] => :environment do |_t, args|
    update_subscriber_list(slug: args[:slug], new_title: args[:new_title], new_slug: args[:new_slug])
  end
end
