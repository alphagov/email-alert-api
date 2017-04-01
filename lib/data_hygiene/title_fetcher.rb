module DataHygiene
  class TitleFetcher
    # Fetch titles for subscriber lists from GovDelivery and update our database
    # with them if we don't have a title already. Log when we have a title which
    # doesn't match GovDelivery's.

    attr_reader :client, :logger, :stats

    def initialize(client: Services.gov_delivery, logger: Logger.new(STDOUT))
      @client = client
      @logger ||= logger
      @stats = Hash.new(0)
    end

    def run
      count = subscriber_lists.count

      logger.info "Fetching and updating titles for #{count} subscriber lists"

      subscriber_lists.each { |subscriber_list| update_title(subscriber_list) }

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

    def update_title(subscriber_list)
      gov_delivery_id = subscriber_list.gov_delivery_id
      return unless topic_name = fetch_topic_title(gov_delivery_id)

      if subscriber_list.title.blank?
        subscriber_list.title = topic_name
        if subscriber_list.save
          @stats[:updated] += 1
          logger.info "#{gov_delivery_id}: title updated to match GovDelivery topic"
        else
          @stats[:update_failed] += 1
          logger.warn "#{gov_delivery_id}: failed to update title"
        end
      elsif subscriber_list.title == topic_name
        @stats[:already_matching] += 1
        logger.info "#{gov_delivery_id}: already has matching title"
      else
        @stats[:different] += 1
        logger.warn "#{gov_delivery_id}: has GD name #{topic_name} but EEA title #{subscriber_list.title}; not overwriting existing title with name"
      end
    end

    def fetch_topic_title(gov_delivery_id)
      begin
        @client.fetch_topic(gov_delivery_id).name
      rescue GovDelivery::Client::TopicNotFound
        @stats[:not_found] += 1
        logger.warn "#{gov_delivery_id}: topic not found on GovDelivery"
        return nil
      rescue GovDelivery::Client::UnknownError, GovDelivery::Client::UnexpectedResponseBodyError => e
        @stats[:error_fetching] += 1
        logger.warn "#{gov_delivery_id}: error fetching topic from GovDelivery: #{e.to_s}"
        return nil
      end
    end
  end
end

