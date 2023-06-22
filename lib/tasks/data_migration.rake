require "csv"

namespace :data_migration do
  desc "Move all subscribers from one subscriber list to another"
  task :move_all_subscribers, %i[from_slug to_slug] => :environment do |_t, args|
    if ENV["SEND_EMAIL"]
      args = args.to_hash.merge!(send_email: ENV["SEND_EMAIL"])
    end

    SubscriberListMover.new(**args).call
  end

  desc "Rename an alert type and all combinations of subscriptions to it"
  task :rename_alert_subscription_lists, %i[from_slug to_slug] => :environment do |_t, args|
    SubscriberList.where("tags->'alert_type' IS NOT NULL").find_each do |list|
      next unless list.tags[:alert_type][:any].include? args[:from_slug]
      next if list.subscriptions.active.empty?

      new_alert_types = (list.tags[:alert_type][:any] - [args[:from_slug]] + [args[:to_slug]]).uniq

      if (new_list = SubscriberList.where("tags->'alert_type' IS NOT NULL").find_all { |l| l.tags[:alert_type][:any].sort == new_alert_types.sort }.first) && list != new_list
        puts "Moving #{list.slug} subscribers to #{new_list.slug}"
        SubscriberListMover.new(from_slug: list.slug, to_slug: new_list.slug).call
      else
        puts "Updating #{list.slug} with tags #{new_alert_types} (was: #{list.tags[:alert_type][:any]})"

        new_tags = list.tags.deep_dup
        new_tags[:alert_type][:any] = new_alert_types
        list.tags = new_tags

        list.save!
      end
    end
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

  # WARNING: this will cause any in-flight signup journeys to 404,
  # as the slug is used as the ID of the list to subscribe to.
  desc "Update subscriber list slug"
  task :update_subscriber_list_slug, %i[slug new_slug] => :environment do |_t, args|
    slug = args[:slug]
    new_slug = args[:new_slug]

    subscriber_list = SubscriberList.find_by(slug:)
    raise "Cannot find subscriber list with #{slug}" if subscriber_list.nil?

    subscriber_list.slug = new_slug

    subscriber_list.save!
    puts "Subscriber list updated with slug: #{new_slug}"
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

  #  This is a temporary task which is required to tidy up following an incident that
  # resulted in users subscribing to malformed lists.

  desc "Move all users subscriber to a malformed list to the equivalent working list "
  task migrate_users_from_bad_lists: :environment do |_t, _args|
    migrator = BadListSubscriptionsMigrator.new

    bad_subscription_counts_before = migrator.bad_lists.map(&:active_subscriptions_count)

    puts "Bad subscriptions count for taxonony emails: #{bad_subscription_counts_before.sum}"
    puts "Running migration..."

    migrator.process_all_lists

    puts "Migration complete"

    bad_lists_with_active_subs_after = migrator.bad_lists.select { |list| list.active_subscriptions_count.positive? }
    bad_subscription_counts_after = bad_lists_with_active_subs_after.map(&:active_subscriptions_count)

    puts "There are #{bad_subscription_counts_after.sum} remaining bad subscriptions for taxonomy lists."
    if bad_lists_with_active_subs_after.present?
      puts "These pages still have bad lists: #{bad_lists_with_active_subs_after.pluck(:url).uniq}."
    end
  end
end
