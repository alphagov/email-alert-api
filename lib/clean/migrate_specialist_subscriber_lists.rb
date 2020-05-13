module Clean
  # A document_type filter was incorrectly added to some subscriber lists
  # via a change to specialist publisher.
  class MigrateSpecialistSubscriberLists
    def migrate_subscribers_to_working_lists(dry_run: true)
      lists.each do |from_list|
        to_list = find_to_list(from_list)
        migrate_list(from_list, to_list, dry_run: dry_run)
      end

      puts "Found #{dry_run ? '' : 'and migrated '}#{lists.count} #{'lists'.pluralize(lists.count)}"
    end

    def lists
      @lists ||= begin
        lists = SubscriberList.where(created_at: Date.new(2019, 12, 13)..Date.new(2020, 1, 22))
        lists.select do |l|
          l.tags != {} && l.title.exclude?("Brexit") &&
            l.matched_content_changes.count.zero? &&
            l.subscribers.activated.count.positive? && l.tags.key?(:document_type)
        end
      end
    end

  private

    def find_to_list(from_list)
      new_tags = from_list.tags
      new_tags.delete :document_type
      query = FindExactQuery.new(
        tags: new_tags,
        links: from_list.links,
        document_type: from_list.document_type,
        email_document_supertype: from_list.email_document_supertype,
        government_document_supertype: from_list.government_document_supertype,
      )
      query.exact_match || create_list!(from_list, new_tags)
    end

    def migrate_list(from_list, to_list, dry_run: true)
      subscribers = from_list.subscribers
      if dry_run
        puts "[DRY RUN] Would've moved #{subscribers.count} active subscribers from #{from_list.slug} to #{to_list.slug}"
        return
      end
      puts "Moving #{subscribers.count} active subscribers from #{from_list.slug} to #{to_list.slug}"

      subscribers.each do |subscriber|
        Subscription.transaction do
          existing_subscription = Subscription.active.find_by(
            subscriber: subscriber,
            subscriber_list: from_list,
          )

          next unless existing_subscription

          existing_subscription.end(reason: :subscriber_list_changed)

          subscribed_to_destination_subscriber_list = Subscription.find_by(
            subscriber: subscriber,
            subscriber_list: to_list,
          )

          if subscribed_to_destination_subscriber_list.nil?
            Subscription.create!(
              subscriber: subscriber,
              subscriber_list: to_list,
              frequency: existing_subscription.frequency,
              source: :subscriber_list_changed,
            )
          end
        end
      end
    end

    def create_list!(from_list, new_tags)
      SubscriberList.create!(
        slug: from_list.slug += "-#{SecureRandom.hex(5)}",
        title: from_list.title,
        tags: new_tags,
        links: from_list.links,
        document_type: from_list.document_type,
        email_document_supertype: from_list.email_document_supertype,
        government_document_supertype: from_list.government_document_supertype,
      )
    end
  end
end
