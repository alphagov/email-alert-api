require "csv"

namespace :support do
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
    pp results
  end

  desc "View most recent email emails for a subscriber"
  task :view_emails, %i[email_address limit] => :environment do |_t, args|
    email_address = args[:email_address]
    limit = args[:limit] ? args[:limit].to_i : 10
    raise ArgumentError, "Provide an email!" if email_address.blank?

    query = Email.where(address: email_address).order(created_at: :desc)
    puts "#{query.count} emails sent to #{email_address}:"
    results = query.limit(limit).map do |email|
      {
        created_at: email.created_at.strftime("%l:%M%P, %-d %B %Y"),
        status: email.status,
        email_subject: email.subject,
        email_uuid: email.id,
        # Confirmation emails have no corresponding subscription at this point. `subscription_slug: nil`
        subscription_slug: SubscriptionContent.find_by(email_id: email.id)&.subscription&.subscriber_list&.slug,
      }
    end
    pp results
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
      active_subscription = Subscription.active.find_by(subscriber_list:, subscriber:)
      if active_subscription
        active_subscription.end(reason: :unsubscribed)
        puts "Unsubscribing #{email_address} from #{subscriber_list_slug}"
      else
        puts "Subscriber #{email_address} already unsubscribed from #{subscriber_list_slug}"
      end
    end
  end

  desc "Unsubscribe all active subscribers from a single subscription list"
  task :unsubscribe_all_subscribers_from_subscription, [:subscriber_list_slug] => :environment do |_t, args|
    subscriber_list_slug = args[:subscriber_list_slug]
    subscriber_list = SubscriberList.find_by(slug: subscriber_list_slug)

    abort("Cannot find subscriber list #{subscriber_list_slug}") if subscriber_list.nil?

    subscribers = subscriber_list.subscribers

    subscribers.each do |subscriber|
      active_subscription = Subscription.active.find_by(subscriber_list:, subscriber:)

      if active_subscription
        active_subscription.end(reason: :unsubscribed)
        puts "Unsubscribing #{subscriber.address} from #{subscriber_list_slug}"
      else
        puts "Subscriber #{subscriber.address} already unsubscribed from #{subscriber_list_slug}"
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

  desc "Query the Notify API for email(s) by email ID"
  task :get_notifications_from_notify_by_email_id, [:id] => :environment do |_t, args|
    NotificationsFromNotify.call(args[:id])
  end

  desc "Send a test email to an email address"
  task :send_test_email, [:email_address] => :environment do |_t, args|
    email = Email.create!(
      address: args[:email_address],
      subject: "Test email",
      body: "This is a test email.",
    )
    SendEmailWorker.perform_async_in_queue(email.id, queue: :send_email_immediate)
  end

  namespace :resend_failed_emails do
    desc "Re-send failed emails by email ids"
    task by_id: [:environment] do |_, args|
      ids = Email.where(id: args.to_a, status: :failed).pluck(:id)
      Email.where(id: ids).update_all(status: :pending, updated_at: Time.zone.now)

      puts "Resending #{ids.length} emails"

      ids.each do |id|
        SendEmailWorker.perform_async_in_queue(id, queue: :send_email_immediate_high)
      end
    end

    desc "Re-send failed emails by date range"
    task :by_date, %i[from to] => [:environment] do |_, args|
      from = Time.iso8601(args.fetch(:from))
      to = Time.iso8601(args.fetch(:to))
      ids = Email.where(created_at: from..to, status: :failed).pluck(:id)
      Email.where(id: ids).update_all(status: :pending, updated_at: Time.zone.now)

      puts "Resending #{ids.length} emails"

      ids.each do |id|
        SendEmailWorker.perform_async_in_queue(id, queue: :send_email_immediate_high)
      end
    end
  end

  namespace :emails do
    desc "Show delivery statistics for a content_id"
    task :stats_for_content_id, %i[content_id start_date end_date] => :environment do |_t, args|
      content_id = args[:content_id]
      start_date = Time.zone.now - 7.days
      end_date = Time.zone.now
      begin
        start_date = Time.zone.strptime(args[:start_date], "%F").beginning_of_day if args[:start_date]
        end_date = Time.zone.strptime(args[:start_date], "%F").end_of_day if args[:end_date]
      rescue ArgumentError
        abort("Cannot parse dates, are they valid ISO8601 dates (YYYY-MM-DD)?")
      end

      sent = Email.where("content_id = ? AND updated_at >= ? AND updated_at <= ?", content_id, start_date, end_date)

      if sent.any?
        puts "#{sent.count} emails sent for #{content_id} between #{start_date} and #{end_date}\n\n"
        puts "Most recent sent on: #{sent.order(:sent_at).first.created_at}\n\n"

        puts "Email Alert API Status (when sending to Notify)\n"
        puts "- Failed: #{sent.where(status: 'failed').count}"
        puts "- Sent:   #{sent.where(status: 'sent').count}\n\n"

        puts "Notify Status (set by callback when delivering)\n"
        puts "- No calback: #{sent.where(notify_status: nil).count}"
        puts "- Permanent Failure: #{sent.where(notify_status: 'permanent-failure').count}"
        puts "- Temporary Failure: #{sent.where(notify_status: 'temporary-failure').count}"
        puts "- Delivered:  #{sent.where(notify_status: 'delivered').count}\n\n"
      else
        puts "No emails sent for #{content_id} between #{start_date} and #{end_date}\n\n"
      end
    end
  end
end
