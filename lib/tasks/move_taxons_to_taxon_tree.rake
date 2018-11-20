desc "Move all duplicated lists with the key :taxons in the link to an equivalent or new list containing :taxon_tree"
task move_taxons_to_taxon_tree: :environment do
  source_lists = SubscriberList.all.select { |list| list.links.key?(:taxons) }

  source_lists.each do |source_list|
    destination_list = FindExactQuery.new(new_params(source_list)).exact_match
    move_all_subscribers(source_list, destination_list)
  rescue StandardError => ex
    puts ex.message
  end
end

def move_all_subscribers(source_subscriber_list, destination_subscriber_list)
  source_subscriptions = Subscription.active.find_by(subscriber_list_id: source_subscriber_list.id)
  raise "No active subscriptions to move from #{source_subscriber_list.slug}" if source_subscriptions.nil?
  subscribers = source_subscriber_list.subscribers.activated
  puts "#{subscribers.count} active subscribers moving from #{source_subscriber_list.slug} to #{destination_subscriber_list.slug}"

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

  puts "#{subscribers.count} active subscribers moved from #{source_subscriber_list.slug} to #{destination_subscriber_list.slug}"
end

def updated_links(list)
  list.links.transform_keys { |key| key == :taxons ? :taxon_tree : key }
end

def new_params(list)
  {
    tags: {},
    links: updated_links(list),
    document_type: list.document_type,
    email_document_supertype: list.email_document_supertype,
    government_document_supertype: list.government_document_supertype
  }
end
