namespace :data_migration do
  desc "Switch immediate subscribers of the specified list slugs to daily digest"
  task switch_to_daily_digest: :environment do |_t, args|
    lists = SubscriberList.where(slug: args.extras)
    raise "One or more lists were not found" if lists.count != args.extras.count

    subscriptions = Subscription.active.immediately.where(subscriber_list: lists)
    raise "No subscriptions to change" if subscriptions.none?

    subscribers = Subscriber.where(id: subscriptions.pluck(:subscriber_id)).index_by(&:id)
    subscriptions_by_subscriber = subscriptions.group_by(&:subscriber_id).transform_keys { |k| subscribers[k] }

    subscriptions_by_subscriber.each do |subscriber, immediate_subscriptions|
      email_id = nil

      subscriber.with_lock do
        immediate_subscriptions.each do |subscription|
          subscription.end(reason: :bulk_immediate_to_digest)

          Subscription.create!(
            subscriber_id: subscription.subscriber_id,
            subscriber_list_id: subscription.subscriber_list_id,
            frequency: :daily,
            source: :bulk_immediate_to_digest,
          )
        end

        email_id = SwitchToDailyDigestEmailBuilder.call(subscriber, immediate_subscriptions)
      end

      DeliveryRequestWorker.perform_async_in_queue(email_id, queue: :default)
    rescue StandardError => e
      puts "Skipping subscriber: #{e}"
    end
  end

  desc "Switch immediate subscribers of the following lists to daily digest (experiment)"
  task switch_to_daily_digest_experiment: :environment do
    Rake::Task["data_migration:switch_to_daily_digest"].invoke(
      *File.read(Rails.root.join("config/experiment_2_slugs.txt")).split("\n"),
    )
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
