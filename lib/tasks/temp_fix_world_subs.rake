desc "Temporary task to fix /world email subscriptions"
task :temp_fix_world_subs, [:for_reals] => :environment do |_, args|
  ApplicationRecord.transaction do
    # We can't get this by API call, since Email Alert API doesn't have an API token for Publishing API
    # File.write("/tmp/world_taxons.csv", CSV.generate { |csv| Edition.live.where(document_type: "taxon").where("base_path ~ '/world/.*'").each { |e| csv << [e.content_id, e.base_path] } })
    world_taxons = CSV.read("lib/tasks/temp_fix_world_subs/world_taxons.csv")
      .map { |line| { content_id: line[0], base_path: line[1] } }

    # We can only get this from inside Whitehall (it's not exposed).
    # File.write("/tmp/world_locations.csv", CSV.generate { |csv| WorldLocation.all.each { |w| csv << [w.content_id, w.slug] } })
    world_locations = CSV.read("lib/tasks/temp_fix_world_subs/world_locations.csv")
      .map { |line| { content_id: line[0], slug: line[1] } }

    # Find taxons where we diverted "/world/<country>/news" to "/world/<country>"
    # Note that the taxon country slugs all match with Whitehall world location slugs
    ambiguous_4_type_world_taxons = world_taxons.select do |world_taxon|
      world_locations.any? { |wl| world_taxon[:base_path] == "/world/#{wl[:slug]}" }
    end

    # e.g. /world/living-in-spain
    # Some of these may not have dead subscriber lists, and we'll ignore them later
    fixable_2a_type_world_taxons = world_taxons - ambiguous_4_type_world_taxons

    # Deletions to apply
    dead_4_type_lists = SubscriberList.where(
      links_digest: ambiguous_4_type_world_taxons.map do |ambiguous_world_taxon|
        HashDigest.new("world_locations" => { "any" => [ambiguous_world_taxon[:content_id]] }).generate
      end,
    )

    # Fixes to apply
    dead_2a_to_2_type_list_mappings = fixable_2a_type_world_taxons.map { |fixable_world_taxon|
      dead_links = { "world_locations" => { "any" => [fixable_world_taxon[:content_id]] } }
      dead_sl = SubscriberList.find_by(links_digest: HashDigest.new(dead_links).generate)

      # do nothing unless a broken list exists
      next unless dead_sl

      alive_links = { "taxon_tree" => { "any" => [fixable_world_taxon[:content_id]] } }
      alive_sl = SubscriberList.find_by(links_digest: HashDigest.new(alive_links).generate)

      # Create a working list to move the broken subscriptions into
      if alive_sl.nil?
        alive_sl = dead_sl.dup
        alive_sl.links = alive_links
        alive_sl.slug += "-#{SecureRandom.hex(5)}" # from subscriber_lists_controller.rb
        alive_sl.save! if args[:for_reals] # so we can do a dry run
      end

      [dead_sl, alive_sl]
    }.compact

    # Report before applying deletions and fixes
    dead_4_type_lists.each do |sl|
      puts "#{sl.title} (#{sl.slug}, #{sl.subscriptions.active.count} subscriptions) - permanently corrupted, deleting"
    end

    dead_2a_to_2_type_list_mappings.each do |dead_sl, alive_sl|
      puts "#{dead_sl.title} (#{dead_sl.slug}, #{dead_sl.subscriptions.active.count} subscriptions) - fixable, merging into '#{alive_sl.slug}'"
    end

    # So we can do a dry run
    next unless args[:for_reals]

    # End all subscriptions to the dead lists we can't fix, so they don't appear to the user
    dead_4_type_lists.each do |dead_list|
      dead_list.subscriptions.active.each do |dead_subscription|
        UnsubscribeService.call(dead_subscription.subscriber, [dead_subscription], :subscriber_list_changed)
      end
    end

    # Fix all subscriptions for dead lists that are unambiguously related to a working list
    dead_2a_to_2_type_list_mappings.each do |dead_list, alive_list|
      next unless dead_list.subscriptions.active.any?

      SubscriberListMover.new(from_slug: dead_list.slug, to_slug: alive_list.slug).call
    end
  end
end
