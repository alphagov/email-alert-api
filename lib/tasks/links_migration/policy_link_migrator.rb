module Tasks
  module LinksMigration
    class PolicyLinkMigrator
      class DodgyBasePathError < StandardError; end

      def populate_policy_links
        relevant_subscriber_lists.each do |list|
          content_item = Services.content_store.content_item(base_path_from(list))

          if content_item.blank?
            raise DodgyBasePathError, <<-ERROR.strip_heredoc
              No content item found for #{base_path_from(list)},
              run the report_non_matching rake task and fix these
              cases before continuing migration.
            ERROR
          end

          if content_item.content_id.blank?
            raise DodgyBasePathError, <<-ERROR.strip_heredoc
              No content item found for #{base_path_from(list)},
              run the report_non_matching rake task and fix these
              cases before continuing migration.
            ERROR
          end

          puts "Updating links in SubscriberList #{list.id}"
          list.update(links: {parent: [content_item.content_id]})
        end
      end

      def report_non_matching_subscriber_lists
        no_content_item = []
        no_content_id   = []

        relevant_subscriber_lists.each do |list|
          print "."
          content_item = Services.content_store.content_item(base_path_from(list))

          if content_item.blank?
            no_content_item << list
            next
          end

          if content_item.content_id.blank?
            no_content_id << list
          end
        end

        puts
        puts "***No content item found***"
        no_content_item.each do |list|
          puts "#{list.id}, #{policy_tag(list)}"
        end
        puts "Total: #{no_content_item.count}"

        puts
        puts "***No content id found***"
        no_content_id.each do |list|
          puts "#{list.id}, #{policy_tag(list)}"
        end
        puts "Total: #{no_content_id.count}"

        puts
        puts "GRAND TOTAL: #{no_content_item.count + no_content_id.count}"
      end

private
      def policy_tag(list)
        # Only one slug is ever specified in policy tags
        list.tags[:policy].first
      end

      def base_path_from(subscriber_list)
        "/government/policies/#{policy_tag(subscriber_list)}"
      end

      def relevant_subscriber_lists
        @relevant_subscriber_lists ||= SubscriberListQuery.new(query_field: :tags)
          .subscriber_lists_with_key(:policy)
      end
    end
  end
end
