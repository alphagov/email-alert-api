class AddMissingPoliciesLinksToPolicySubscriberLists < ActiveRecord::Migration[5.2]
  def change
    SubscriberList.all.each do |subscriber_list|
      next unless subscriber_list.tags.key? :policies

      if subscriber_list.links.empty?
        policy_slug = subscriber_list.tags[:policies].first
        content_id = Services
                       .content_store
                       .content_item("/government/policies/#{policy_slug}")
                       .to_h
                       .fetch('content_id')

        subscriber_list.update!(links: { 'policies' => [content_id] })

        puts "updated: #{policy_slug} with content_id #{content_id}"
      end
    end
  end
end
