module DataHygiene
  class TitleFetcher
    # Fetch all topics from GovDelivery and update the subscriber lists in our
    # database with the title for each if we don't have a title already. Log
    # when we have a title which doesn't match GovDelivery's.

    attr_reader :client, :logger, :stats

    def initialize(client: Services.gov_delivery, logger: Logger.new(STDOUT))
      @client = client
      @logger ||= logger
      @stats = Hash.new(0)
    end

    def run
      all_topics = fetch_all_topics

      count = subscriber_lists.count
      logger.info "Updating titles for #{count} subscriber lists"

      subscriber_lists.each do |subscriber_list|
        update_title(subscriber_list, all_topics[subscriber_list.gov_delivery_id])
      end

      logger.info ''
      logger.info "Done:"
      stats.each do |k, v|
        logger.info "  #{k}: #{v}"
      end
    end

  private

    def subscriber_lists
      SubscriberList.all
    end

    def fetch_all_topics
      logger.info "Fetching all topics from GovDelivery..."
      all_topics = client.fetch_topics['topics']
      logger.info "#{all_topics.size} topics found on GovDelivery"

      all_topics.map { |topic| [topic['code'], topic['name']] }.to_h
    end

    def update_title(subscriber_list, gov_delivery_name)
      gov_delivery_id = subscriber_list.gov_delivery_id

      unless gov_delivery_name.present?
        @stats[:not_found] += 1
        logger.warn "#{gov_delivery_id}: no name found for topic from GovDelivery"
        return
      end

      if subscriber_list.title.blank?
        subscriber_list.title = gov_delivery_name
        if subscriber_list.save
          @stats[:updated] += 1
          logger.info "#{gov_delivery_id}: title updated to match GovDelivery topic"
        else
          @stats[:update_failed] += 1
          logger.warn "#{gov_delivery_id}: failed to update title"
        end
      elsif subscriber_list.title == gov_delivery_name
        @stats[:already_matching] += 1
        logger.info "#{gov_delivery_id}: already has matching title"
      else
        @stats[:different] += 1
        logger.warn "#{gov_delivery_id}: has GD name #{gov_delivery_name} but EEA title #{subscriber_list.title}; not overwriting existing title with name"
      end
    end
  end
end
