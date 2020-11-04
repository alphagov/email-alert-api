require "csv"

namespace :data_migration do
  desc "Experiment 3 in switching immediate subscribers to daily digest"
  task switch_to_daily_digest_experiment: :environment do
    lists = CSV.read(Rails.root.join("config/experiment_3_lists.csv"), headers: true)

    list_count = SubscriberList.where(slug: lists.map { |l| l.fetch("slug") }).count
    raise "One or more lists were not found" if lists.size != list_count

    subscriber_and_subscription_ids = lists.each_with_object({}) do |list, memo|
      subscription_scope = Subscription.active
                                       .immediately
                                       .joins(:subscriber_list)
                                       .where("subscriber_lists.slug": list.fetch("slug"))

      total = subscription_scope.count
      to_migrate = (total * list.fetch("proportion").to_f).round
      random_subscriptions = subscription_scope.limit(to_migrate)
                                               .order("RANDOM()")
                                               .pluck(:id, :subscriber_id)

      random_subscriptions.each do |(subscription_id, subscriber_id)|
        memo[subscriber_id] ||= []
        memo[subscriber_id] << subscription_id
      end

      puts "Migrating #{random_subscriptions.size} of #{total} immediate subscribers of #{list.fetch('slug')}"
    end

    subscribers = Subscriber.where(id: subscriber_and_subscription_ids.keys)
    subscribers.find_each.with_index do |subscriber, index|
      email_id = nil
      now = Time.zone.now
      subscription_ids = subscriber_and_subscription_ids.fetch(subscriber.id)

      subscriber.with_lock do
        immediate_subscriptions = Subscription.active.immediately.where(id: subscription_ids)

        new_subscriptions = immediate_subscriptions.map do |subscription|
          {
            subscriber_id: subscriber.id,
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

      progress = index + 1
      total = subscriber_and_subscription_ids.size
      puts "Processed #{progress} of #{total} subscribers" if (progress % 1000).zero?
    rescue StandardError => e
      puts "Skipping subscriber #{subscriber.id}: #{e}"
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

  desc "Update one of the tags in a subscriber list"
  task :update_subscriber_list_tag, %i[key old_criterion new_criterion] => :environment do |_t, args|
    SubscriberList.where("tags->>'#{args[:key]}' IS NOT NULL").find_each do |list|
      old_criteria = list.tags[args[:key].to_sym][:any]
      next unless old_criteria.include?(args[:old_criterion])

      new_criteria = old_criteria - [args[:old_criterion]] + [args[:new_criterion]]
      list.update!(tags: list.tags.merge(args[:key].to_sym => { any: new_criteria }))
      puts "Updated #{args[:key]} in #{list.title} to #{new_criteria}"
    end
  end
end
