require "csv"

namespace :data_migration do
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

  desc "Temporary task to update all existing Brexit checker list titles"
  task temp_update_all_brexit_list_titles: :environment do
    SubscriberList
      .where("tags->'brexit_checklist_criteria' IS NOT NULL")
      .update_all(title: "Brexit checker results")
  end
end
