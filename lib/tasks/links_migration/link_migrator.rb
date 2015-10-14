module Tasks
  module LinksMigration
    class LinkMigrator
      def populate_topic_links
        relevant_subscriber_lists.each do |sl|
          base_path = base_path_from(sl)
          content_item = Services.content_store.content_item(namespaced(base_path))
          if content_item && content_item.content_id.present?
            puts "Updating links in SubscriberList #{sl.id}"
            sl.update(links: {topics: [content_item.content_id]})
          end
        end
      end

      def destroy_non_matching_subscriber_lists
        relevant_subscriber_lists.each do |sl|
          base_path = base_path_from(sl)
          content_item = Services.content_store.content_item(namespaced(base_path))

          if content_item.blank? || content_item.content_id.blank?
            puts "Destroying Subscriber List id: #{sl.id}"
            sl.destroy!
          end
        end
      end

    private

      def base_path_from(subscriber_list)
        # Only one base path is ever specified in topic tags
        subscriber_list.tags[:topics].first
      end

      def relevant_subscriber_lists
        @relevant_subscriber_lists ||= SubscriberListQuery.new(query_field: :tags)
          .subscriber_lists_with_key(:topics)
      end

      def namespaced(base_path)
        # Because the base paths in email-alert-api don't include '/topic'
        "/topic/#{base_path}"
      end
    end
  end
end
