class RemoveCpsService
  def delete_subscriber_lists
    subscriber_lists = fetch_subscriber_lists

    subscriptions = Subscription.where(subscriptions: { subscriber_list: subscriber_lists })
    raise "Can't have any subscribers left" unless subscriptions.empty?

    count = subscriber_lists.count
    subscriber_lists.each_with_index do |subscriber_list, index|
      SubscriberList.transaction do
        matching_list = matching_subscriber_list(subscriber_list)
        move_matched_content_changes(subscriber_list, matching_list)
        subscriber_list.destroy
      end
      puts "Done #{index} out of #{count} subscriber lists"
    end
  end

  def deactivate_subscriber_lists
    subscriber_lists = fetch_subscriber_lists
    count = subscriber_lists.count
    subscriber_lists.each_with_index do |subscriber_list, index|
      SubscriberList.transaction do
        matching_list = matching_subscriber_list(subscriber_list)
        if matching_list.nil?
          content_purpose_supergroup_to_tags(subscriber_list)
        else
          move_subscriptions(subscriber_list, matching_list)
        end
      end
      puts "Done #{index} out of #{count} subscriber lists"
    end
  end

private

  def fetch_subscriber_lists
    SubscriberList.where('content_purpose_supergroup IS NOT NULL')
  end

  def active_subscribers(subscriber_list)
    Subscriber.joins(:subscriptions).where(subscriptions: { subscriber_list: subscriber_list, ended_at: nil })
  end

  def move_subscriptions(from_subscriber_list, to_subscriber_list)
    subscriptions = from_subscriber_list.subscriptions
    subscribers = active_subscribers(to_subscriber_list)
    subscriptions.each do |subscription|
      if subscription.active? && subscribers.include?(subscription.subscriber)
        subscription.end(reason: 'subscriber_list_changed')
      end
      subscription.update_attribute(:subscriber_list, to_subscriber_list)
    end
  end

  def move_matched_content_changes(from_subscriber_list, to_subscriber_list)
    to_ids = to_subscriber_list.matched_content_changes.pluck(:content_change_id)

    duplicates = MatchedContentChange.where(subscriber_list: from_subscriber_list, content_change_id: to_ids)
    non_duplicates = MatchedContentChange.where(subscriber_list: from_subscriber_list).where.not(content_change_id: to_ids)
    non_duplicates.each do |matched_content_change|
      matched_content_change.update(subscriber_list: to_subscriber_list)
    end
    duplicates.try(:first).try(:delete)
  end

  def content_purpose_supergroup_to_tags(subscriber_list)
    subscriber_list.update(tags: updated_tags(subscriber_list),
                           content_purpose_supergroup: nil)
  end

  def matching_subscriber_list(subscriber_list)
    FindExactQuery.new(tags: updated_tags(subscriber_list),
                       links: {},
                       document_type: subscriber_list.document_type,
                       email_document_supertype: subscriber_list.email_document_supertype,
                       government_document_supertype: subscriber_list.government_document_supertype,
                       slug: nil,
                       content_purpose_supergroup: nil).exact_match
  end

  def updated_tags(subscriber_list)
    subscriber_list.tags.merge(content_purpose_supergroup: { any: [subscriber_list.content_purpose_supergroup] })
  end
end
