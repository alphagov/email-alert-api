namespace :clean do
  desc "Remove SubscriberLists with no subscriptions"
  task remove_empty_subscriberlists: :environment do
    dry_run = ENV["DRY_RUN"] != "no"
    cleaner = Clean::EmptySubscriberLists.new
    cleaner.remove_empty_subscriberlists(dry_run: dry_run)
  end

  desc "Temporary task to close subscriptions to FCO/DFID lists that will no " \
       "longer receive emails"
  task close_fco_dfid_subscriptions: :environment do
    fco_content_id = "db994552-7644-404d-a770-a2fe659c661f"
    dfid_content_id = "9adfc4ed-9f6c-4976-a6d8-18d34356367c"

    lists = SubscriberList.where("links->'organisations'->>'any' LIKE ?", "%#{fco_content_id}%")
      .or(SubscriberList.where("links->'organisations'->>'any' LIKE ?", "%#{dfid_content_id}%"))

    stats = { lists: 0, subscriptions: 0 }

    lists.find_each do |list|
      other_organisations = list.links[:organisations][:any] - [fco_content_id, dfid_content_id]
      # we won't close subscriptions for lists for other organisations
      next if other_organisations.any?

      list.subscriptions.active.includes(:subscriber).find_each do |subscription|
        UnsubscribeService.call(subscription.subscriber,
                                [subscription],
                                :subscriber_list_changed)
        stats[:subscriptions] += 1

        puts "Processed #{stats[:subscriptions]} subscriptions" if (stats[:subscriptions] % 1000).zero?
      end

      stats[:lists] += 1
    end

    puts "Closed #{stats[:subscriptions]} subscriptions for #{stats[:lists]} lists"
  end
end
