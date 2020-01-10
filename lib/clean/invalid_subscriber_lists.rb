module Clean
  class InvalidSubscriberLists
    def invalid_lists
      SubscriberList.select(&:invalid?)
    end

    def destroy_invalid_subscriber_lists(dry_run: true)
      count = 0
      invalid_lists.each do |list|
        next if list.subscriptions.active.any?

        count += 1
        puts "#{dry_run ? '[DRY RUN]' : ''} Deleting subscriber_list #{list.slug}"
        list.destroy unless dry_run
      end
      dry_msg = dry_run ? "[DRY RUN] Would have deleted" : "Deleted"
      puts "#{dry_msg} #{count} subscriber lists"
    end
  end
end
