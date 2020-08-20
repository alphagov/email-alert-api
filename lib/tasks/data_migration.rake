namespace :data_migration do
  desc "Switch immediate subscribers of the specified list slugs to daily digest"
  task switch_to_daily_digest: :environment do |_t, args|
    list_ids = SubscriberList.where(slug: args.extras).pluck(:id)
    raise "One or more lists were not found" if list_ids.count != args.extras.count

    subscriptions = Subscription.active.immediately.where(subscriber_list_id: list_ids)
    raise "No subscriptions to change" if subscriptions.none?

    subscribers = Subscriber.where(id: subscriptions.pluck(:subscriber_id))

    subscribers.find_in_batches(batch_size: 1000).with_index do |subscriber_batch, index|
      puts "Processing batch #{index}"

      subscriptions_by_subscriber = subscriptions
        .where(subscriber: subscriber_batch)
        .includes(:subscriber, :subscriber_list)
        .group_by(&:subscriber)

      subscriptions_by_subscriber.each do |subscriber, immediate_subscriptions|
        email_id = nil
        now = Time.zone.now

        subscriber.with_lock do
          new_subscriptions = immediate_subscriptions.map do |subscription|
            {
              subscriber_id: subscription.subscriber_id,
              subscriber_list_id: subscription.subscriber_list_id,
              frequency: :daily,
              source: :bulk_immediate_to_digest,
              created_at: now,
              updated_at: now,
            }
          end

          Subscription.where(id: immediate_subscriptions.map(&:id)).update_all(
            ended_reason: :bulk_immediate_to_digest,
            ended_at: now,
          )

          Subscription.insert_all!(new_subscriptions)

          email_id = SwitchToDailyDigestEmailBuilder.call(
            subscriber, immediate_subscriptions
          )
        end

        DeliveryRequestWorker.perform_async_in_queue(email_id, queue: :default)
      rescue StandardError => e
        puts "Skipping subscriber: #{e}"
      end
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
