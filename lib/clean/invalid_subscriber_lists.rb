module Clean
  # InvalidSubscriberLists enables us to find and correct subscriber lists
  # with invalid tags.
  class InvalidSubscriberLists
    def lists
      SubscriberList.select(&:invalid?)
    end

    def valid_list(invalid_list, dry_run: true)
      return unless subscriber_lists?([invalid_list])

      return unless invalid_list.invalid?

      unless invalid_list.subscribers.activated.any?
        puts "NoSubscribersError: Did not create a new subscriber list for invalid list #{invalid_list.id}: #{invalid_list.slug}, as there were no active subscribers"
        return
      end

      slug = invalid_list.slug + '-untagged'
      list = SubscriberList.find_by(slug: slug)
      return list unless list.nil?

      new_list = SubscriberList.new(
        document_type: invalid_list.document_type,
        email_document_supertype: invalid_list.email_document_supertype,
        government_document_supertype: invalid_list.government_document_supertype,
        links: tags_to_links(invalid_list.tags),
        slug: slug,
        title: invalid_list.title,
      )

      new_list.save! unless dry_run

      new_list
    rescue StandardError => e
      puts "InvalidTagValueError: Could not create subscriber list from an invalid list. invalid_id: #{invalid_list.id}
      invalid_slug: #{invalid_list.slug} as we couldn't create a valid subscriber list: #{e.message}"
    end

    def copy_subscribers(from_list, to_list, dry_run: true)
      return unless subscriber_lists?([from_list, to_list])

      subscribers = from_list.subscribers.activated
      total_subscribers = subscribers.count
      moved = 0
      subscribers.each do |subscriber|
        Subscription.transaction do
          existing_subscription = Subscription.active.find_by(
            subscriber: subscriber,
            subscriber_list: from_list,
          )

          next unless existing_subscription

          # Check if they have already subscribed
          subscribed_to_destination_subscriber_list = Subscription.find_by(
            subscriber: subscriber,
            subscriber_list: to_list
          )

          # Subscribed them if they haven't already been subscribed
          if subscribed_to_destination_subscriber_list.nil?
            moved += 1
            unless dry_run
              Subscription.create!(
                subscriber: subscriber,
                subscriber_list: to_list,
                frequency: existing_subscription.frequency,
                source: :subscriber_list_changed
              )
            end
          end
        end
      end

      dry = dry_run ? '[DRY RUN] Would have copied' : 'copied'
      puts "#{dry} #{moved} of #{total_subscribers} subscribers from list #{from_list.slug} to #{to_list.slug}"
    end

    def deactivate_invalid_subscriptions(dry_run: true)
      dry_msg = dry_run ? "[DRY RUN] Would have deactivated" : "Deactivated"
      lists.each do |list|
        SubscriberList.transaction do
          subscriptions = list.subscriptions.active
          count = subscriptions.count
          subscriptions.each do |subscription|
            subscription.end(reason: :subscriber_list_changed) unless dry_run
          end
          puts "#{dry_msg} #{count} subscription(s) on subscriber list #{list.slug}"
        end
      end
    end

  private

    def tags_to_links(tags)
      tags.each_with_object({}) do |(key, value), links|
        if key == :part_of_taxonomy_tree
          links[:taxon_tree] = value
        elsif SubscriberList::TAGS_BLACKLIST.include? key
          value.keys.each { |any_or_all|
            links[key] ||= {}
            links[key][any_or_all] = tag_slugs_to_ids(key, value[any_or_all])
          }
        else
          links[key] = value
        end
      end
    end

    def tag_slugs_to_ids(key, values)
      case key
      when :people
        values.map { |slug| people_content_id(slug) }
      when :organisations
        values.map { |slug| organisation_content_id(slug) }
      when :world_locations
        values.map { |slug| world_location_content_id(slug) }
      end
    end

    def organisation_content_id(slug)
      slug = CGI::escape(slug)
      @organisations ||= {}
      cached = @organisations[slug]
      return cached unless cached.nil?

      path = "/government/organisations/#{slug}"
      item = Services.content_store.content_item(path).to_h
      id = item['content_id']

      @organisations[slug] = id
    end

    def people_content_id(slug)
      slug = CGI::escape(slug)
      @people ||= {}
      cached = @people[slug]
      return cached unless cached.nil?

      path = "/government/people/#{slug}"
      item = Services.content_store.content_item(path).to_h
      id = item['content_id']

      @people[slug] = id
    end

    def world_location_content_id(slug)
      slug = CGI::escape(slug)
      @world_locations ||= begin
        locations = GdsApi.worldwide.world_locations.with_subsequent_pages.to_a
        locations.each_with_object({}) { |location, result_hash|
          result_hash[location.dig('details', 'slug')] = location.dig('content_id')
        }
      end

      @world_locations[slug]
    end

    def subscriber_lists?(objects)
      objects.all? { |obj| obj.instance_of? SubscriberList }
    end
  end
end
