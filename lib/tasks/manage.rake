require "csv"

# Example input:
# [{ status: "Inactive (unsubscribed)", subscriber_list: "Test foo (slug: test-foo)", frequency: "daily", ... }, {...}]
#
# Example output:
# | Status                  | SubscriberList            | Frequency | Timeline                                                       |
# | Inactive (unsubscribed) | Test foo (slug: test-foo) | daily     | Subscribed 2020-04-18 15:21:20 +0100, Ended 2020-05-12 11:41:04 +0100 |
# | Active                  | Bar bar (slug: bar-bar)   | weekly    | Subscribed 2019-06-10 13:48:43 +0100                           |
def hash_to_table(hash)
  columns = []
  hash.first.keys.each do |key|
    heading = key.to_s.humanize
    longest_value = hash.map { |row| row[key].to_s.size }.max
    columns << {
      id: key,
      label: heading,
      width: [longest_value, heading.size].max,
    }
  end

  table = "| #{columns.map { |column| column[:label].ljust(column[:width]) }.join(' | ')} |\n"
  hash.each do |row|
    padded_values = row.keys.map do |key|
      column_width = columns.find { |c| c[:id] == key }[:width]
      row[key].to_s.ljust(column_width)
    end
    table += "| #{padded_values.join(' | ')} |\n"
  end
  table
end

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
    puts hash_to_table(results)
  end

  desc "View most recent email delivery attempts for a subscriber"
  task :view_emails, %i[email_address limit] => :environment do |_t, args|
    email_address = args[:email_address]
    limit = args[:limit].to_i || 10
    subscriber = Subscriber.find_by_address(email_address)
    abort("Cannot find any subscriber with email address #{email_address}.") if subscriber.nil?

    subscription_ids = subscriber.subscriptions.pluck(:id)
    subscriptions_contents = SubscriptionContent.where(subscription_id: subscription_ids).last(limit)
    confirmation_emails = Email.where(subject: "Confirm your subscription", address: email_address).last(limit)
    all_emails = (subscriptions_contents.map(&:email) + confirmation_emails).sort_by(&:created_at).last(limit)

    results = all_emails.map do |email|
      {
        created_at: email.created_at,
        status: email.status,
        delivery_attempts: DeliveryAttempt.where(email_id: email.id).count,
        email_subject: email.subject,
        email_uuid: email.id,
        # Confirmation emails have no corresponding subscription at this point. `subscription_slug: nil`
        subscription_slug: SubscriptionContent.find_by(email_id: email.id)&.subscription&.subscriber_list&.slug,
      }
    end
    puts hash_to_table(results)
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
        UnsubscribeService.call(subscriber, [active_subscriptions.last], :unsubscribed)
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
      UnsubscribeAllService.call(subscriber, :unsubscribed)
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
