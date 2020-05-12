require "csv"

namespace :manage do
  desc "View all subscriptions for a subscriber"
  task :view_subscriptions, [:email_address] => :environment do |_t, args|
    email_address = args[:email_address]
    subscriber = Subscriber.find_by_address(email_address)
    abort("Cannot find any subscriber with email address #{email_address}.") if subscriber.nil?

    results = subscriber.subscriptions.map do |subscription|
      subscriber_list = SubscriberList.find(subscription.subscriber_list_id)
      {
        status: subscription.ended_at.present? ? "Inactive (#{subscription.ended_reason})" : "Active",
        subscriber_list: "#{subscriber_list.title} (slug: #{subscriber_list.slug})",
        frequency: subscription.frequency.to_s,
        timeline: "Subscribed #{subscription.created_at}#{subscription.ended_at.present? ? ", Ended #{subscription.ended_at}" : ''}",
      }
    end
    columns = results.first.each_with_object({}) do |(col, _), h|
      heading = col.to_s.humanize
      h[col] = { label: heading, width: [results.map { |g| g[col].size }.max, heading.size].max }
    end

    # Example output:
    # | Status                  | SubscriberList            | Frequency | Timeline                                                       |
    # | Inactive (unsubscribed) | Test foo (slug: test-foo) | daily     | Subscribed 2020-04-18 15:21:20 +0100, Ended 2020-05-12 11:41:04 +0100 |
    # | Active                  | Bar bar (slug: bar-bar)   | weekly    | Subscribed 2019-06-10 13:48:43 +0100                           |
    puts "| #{columns.map { |_, g| g[:label].ljust(g[:width]) }.join(' | ')} |"
    results.each do |h|
      str = h.keys.map { |k| h[k].ljust(columns[k][:width]) }.join(" | ")
      puts "| #{str} |"
    end
  end

  desc "Change the email address of a subscriber"
  task :change_email_address, %i[old_email_address new_email_address] => :environment do |_t, args|
    old_email_address = args[:old_email_address]
    new_email_address = args[:new_email_address]

    subscriber = Subscriber.find_by_address(old_email_address)
    abort("Cannot find any subscriber with email address #{old_email_address}.") if subscriber.nil?

    subscriber.address = new_email_address
    if subscriber.save!
      puts "Changed email address for #{old_email_address} to #{new_email_address}"
    else
      puts "Error changing email address for #{old_email_address} to #{new_email_address}"
    end
  end

  desc "Unsubscribe a subscriber from a single subscription"
  task :unsubscribe_single_subscription, %i[email_address subscriber_list_slug] => :environment do |_t, args|
    email_address = args[:email_address]
    subscriber_list_slug = args[:subscriber_list_slug]
    subscriber = Subscriber.find_by_address(email_address)
    subscriber_list = SubscriberList.find_by(slug: subscriber_list_slug)
    if subscriber.nil?
      puts "Subscriber #{email_address} not found"
    elsif subscriber_list.nil?
      puts "Subscriber list #{subscriber_list_slug} not found"
    elsif !(subscriber.subscriptions.pluck(:subscriber_list_id).include? subscriber_list.id)
      puts "Subscriber #{email_address} does not appear to be signed up for #{subscriber_list_slug}"
    else
      active_subscriptions = Subscription.active.where(subscriber_list: subscriber_list, subscriber: subscriber)
      if active_subscriptions.empty?
        puts "Subscriber #{email_address} already unsubscribed from #{subscriber_list_slug}"
      else
        UnsubscribeService.subscription!(active_subscriptions.last, :unsubscribed)
        puts "Unsubscribing from #{email_address} from #{subscriber_list_slug}"
      end
    end
  end

  desc "Unsubscribe a subscriber from all subscriptions"
  task :unsubscribe_all_subscriptions, [:email_address] => :environment do |_t, args|
    email_address = args[:email_address]
    subscriber = Subscriber.find_by_address(email_address)
    if subscriber.nil?
      puts "Subscriber #{email_address} not found"
    else
      puts "Unsubscribing #{email_address}"
      UnsubscribeService.subscriber!(subscriber, :unsubscribed)
    end
  end

  desc "Unsubscribe a list of subscribers (from a CSV file) from all subscriptions"
  task :unsubscribe_bulk_from_csv, [:csv_file_path] => :environment do |_t, args|
    email_addresses = CSV.read(args[:csv_file_path])
    email_addresses.each do |email_address|
      Rake::Task["manage:unsubscribe_single"].invoke(email_address[0])
    end
  end

  desc "Move all subscribers from one subscriber list to another"
  task :move_all_subscribers, %i[from_slug to_slug] => :environment do |_t, args|
    if ENV["SEND_EMAIL"]
      args = args.to_hash.merge!(send_email: ENV["SEND_EMAIL"])
    end

    SubscriberListMover.new(**args).call
  end

  desc "Find subscriber lists by title match"
  task :find_subscriber_list_by_title, %i[title] => :environment do |_t, args|
    title = args[:title]
    subscriber_lists = SubscriberList.where("title ILIKE ?", "%#{title}%")

    raise "Cannot find any subscriber lists with title containing `#{title}`" if subscriber_lists.nil?

    puts "Found #{subscriber_lists.count} subscriber lists containing '#{title}'"

    subscriber_lists.each do |subscriber_list|
      puts "============================="
      puts "title: #{subscriber_list.title}"
      puts "slug: #{subscriber_list.slug}"
    end
  end

  desc "Update subscriber list title and slug"
  task :update_subscriber_list, %i[slug new_title new_slug] => :environment do |_t, args|
    slug = args[:slug]
    new_title = args[:new_title]
    new_slug = args[:new_slug]

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
end
