require "tasks/links_migration/policy_link_migrator"

namespace :links_migration do
  namespace :for_policies do

    desc "Print a mapping illustrating which policy lists need to have their users moved by govdelivery"
    task report_lists_to_be_merged: [:environment] do
      tagged_with_policies = SubscriberListQuery.new.subscriber_lists_with_key(:policies)
      tagged_with_policy   = SubscriberListQuery.new.subscriber_lists_with_key(:policy)

      no_equivalent_found = []
      remap_count = 0

      tagged_with_policies.each do |list|
        policy_equivalent = tagged_with_policy.find { |l| l.tags[:policy] == list.tags[:policies] }
        if policy_equivalent.present?
          puts "#{list.tags} => #{policy_equivalent.tags}"
          puts "#{list.gov_delivery_id} => #{policy_equivalent.gov_delivery_id}"
          puts
          remap_count += 1
        else
          no_equivalent_found << list
        end
      end

      if no_equivalent_found.present?
        puts
        puts "========================================================================="
        puts "No policy equivalent found, change tags keyed with 'policies' to 'policy'"
        puts "========================================================================="
        no_equivalent_found.each { |list| puts "#{list.id}, #{list.tags}" }
      end

      puts
      puts "Total remaps: #{remap_count}"
      puts
    end

    desc "Print out a report of policy subscriber lists with no obvious content ID match in the content store"
    task report_non_matching: [:environment] do
      Tasks::LinksMigration::PolicyLinkMigrator.new.report_non_matching_subscriber_lists
    end

    desc "Populate empty links fields with policies, based on SubscriberList#tags"
    task populate_links: [:environment] do
      Tasks::LinksMigration::PolicyLinkMigrator.new.populate_policy_links
    end
  end

end
