module BulkUnsubscribeService
  class SubscriptionDetails
    def initialize(subscription, policy_area_path, taxon_path)
      @subscription = subscription
      @policy_area = ContentItem.new(policy_area_path)
      @replacement = ContentItem.new(taxon_path)
    end

    def subscriber_list
      @_subscriber_list = @subscription.subscriber_list
    end

    def title
      subscriber_list.title
    end

    def links
      subscriber_list.links
    end

    def replacement_title
      if subscriber_list[:email_document_supertype] == 'announcements' ||
          subscriber_list[:email_document_supertype] == 'publications'
        @subscription.subscriber_list.title.gsub(@policy_area.title, @replacement.title)
      else
        @replacement.title
      end
    end

    def replacement_url
      if subscriber_list[:email_document_supertype] == 'announcements' ||
          subscriber_list[:email_document_supertype] == 'publications'

        uri = URI.parse(PublicUrlService.absolute_url(path: "/government/#{subscriber_list[:email_document_supertype]}"))
        policy_area_ids = links.dig(:policy_areas, :any) || []

        query_hash = {}
        query_hash['people[]'] = (links.dig(:people, :any) || []).map do |id|
          BulkUnsubscribeService.person_slug(id)
        end
        query_hash['world_locations[]'] = (links.dig(:world_locations, :any) || []).map do |id|
          BulkUnsubscribeService.world_location_slug(id)
        end
        query_hash['departments[]'] = (links.dig(:organisations, :any) || []).map do |id|
          BulkUnsubscribeService.organisation_slug(id)
        end
        taxon_paths = policy_area_ids.map do |policy_area_id|
          BulkUnsubscribeService.taxon_path(policy_area_id)
        end
        query_hash['taxons[]'] = taxon_paths.map do |taxon_path|
          BulkUnsubscribeService.taxonomy.get_taxon_content_id(taxon_path)
        end
        query_hash['subtaxons[]'] = taxon_paths.map do |taxon_path|
          BulkUnsubscribeService.taxonomy.get_subtaxon_content_id(taxon_path)
        end

        uri.query = URI.encode_www_form(Hash[query_hash.map { |key, values| [key, values.compact] }])
        uri.to_s
      else
        @replacement.url
      end
    end
  end
end
