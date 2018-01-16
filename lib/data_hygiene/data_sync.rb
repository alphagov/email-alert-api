module DataHygiene
  class DataSync
    PRODUCTION_ACCOUNT_CODE = "UKGOVUK".freeze
    THREAD_COUNT = 40
    DEFAULT_DELETE_WAIT = 60 # time to wait for all deletions to complete

    attr_reader :logger

    def initialize(logger = Logger.new(STDOUT), delete_wait = DEFAULT_DELETE_WAIT)
      @logger ||= logger
      @delete_wait = delete_wait
    end

    def run
      return unless valid?

      update_delivery_id!

      logger.info "Retrieving data from servers.."

      # determine which topics/subscriber_lists already exist and which have been
      # modified/created since the last data sync
      matching = topics & subscriber_lists
      to_be_deleted = topics - subscriber_lists
      to_be_created = subscriber_lists - topics

      # Handle rows with duplicate codes but different titles, because one of those may
      # exist in GovDelivery already so we don't want to try to create/delete another
      # topic with the same id
      matched_codes = matching.map(&:last)
      skip_deletion, to_be_deleted = to_be_deleted.partition { |_, gov_delivery_id| matched_codes.include?(gov_delivery_id) }
      skip_creation, to_be_created = to_be_created.partition { |_, gov_delivery_id| matched_codes.include?(gov_delivery_id) }

      logger.info "#{to_be_deleted.count} to be deleted, skipping #{skip_deletion.count} due to duplicate Gov Delivery ID's"
      logger.info "#{to_be_created.count} to be created, skipping #{skip_creation.count} due to duplicate Gov Delivery ID's"
      logger.info "#{matching.count} already correctly exist"

      delete_topics_from_gov_delivery(to_be_deleted)

      create_topics_on_gov_delivery(to_be_created)
    end

    def valid?
      unless ENV["ALLOW_GOVDELIVERY_SYNC"] == "allow"
        logger.info "Syncing GovDelivery has not been configured for this environment."
        logger.info "Running this against production GovDelivery would be a really bad idea."
        logger.info "If you're sure you want to run this, export ALLOW_GOVDELIVERY_SYNC='allow'"

        return false
      end

      unless EmailAlertAPI.config.gov_delivery[:hostname] == "stage-api.govdelivery.com"
        logger.info "It looks like you're running this sync with a non-staging GovDelivery configuration."
        logger.info "Running this against production GovDelivery would be a really bad idea."
        logger.info "If the GovDelivery staging hostname has changed, please update this application and try again."

        return false
      end

      true
    end

    def update_delivery_id!
      environment_account_code = EmailAlertAPI.config.gov_delivery[:account_code]

      unless environment_account_code == PRODUCTION_ACCOUNT_CODE
        logger.info "Updating topics in subscriber lists so that prefixes match account id for this environment..."

        SubscriberList.update_all(
          "gov_delivery_id = replace(gov_delivery_id, '#{PRODUCTION_ACCOUNT_CODE}_', '#{environment_account_code}_')"
        )

        logger.info "Done."
      end
    end

    def subscriber_lists
      @subscriber_lists ||= SubscriberList
        .where.not(gov_delivery_id: nil)
        .distinct
        .pluck(:title, :gov_delivery_id)
        .map do |title, gov_delivery_id|
          [title.strip, gov_delivery_id]
        end
    end

    def topics
      @topics ||= Services.gov_delivery
        .fetch_topics.fetch("topics", [])
        .map { |topic| [topic["name"].strip, topic["code"]] }
    end

    def delete_topics_from_gov_delivery(list)
      if list.blank?
        logger.info "No topics to be deleted in GovDelivery."
      else
        logger.warn "Deleting remote topics.."

        batch_size = [list.count, (list.count.to_f / THREAD_COUNT).ceil].min

        threads = list.each_slice(batch_size).map do |batch|
          Thread.new do
            batch.each do |title, gov_delivery_id|
              logger.warn "-- Deleting #{gov_delivery_id} - #{title}"
              Services.gov_delivery.delete_topic(gov_delivery_id)
            end
          end
        end
        threads.each(&:join)

        # GovDelivery delete topics asynchronously and are only eventually
        # consistent on deletes. We wait here to give the deletes a chance to
        # process, and then perform a retry if the create fails
        logger.info "Waiting for #{@delete_wait} seconds for topics to be asynchronously deleted"

        @delete_wait.times do
          sleep 1
          print "."
        end
      end
    end

    def create_topics_on_gov_delivery(list)
      if list.empty?
        logger.info "No topics to be created"
        nil
      else
        6.times.each do |i|
          logger.info "Attempting to create subscriber lists: Attempt #{i}"
          list = create_topics(list)
          return if list.empty? # rubocop:disable Lint/NonLocalExitFromIterator
          sleep 2
        end

        logger.warn "Failed to create all topics"
        raise "Failed to create all topics"
      end
    end

    def create_topics(list)
      retry_create = []
      list.each do |title, gov_delivery_id|
        logger.info "-- Creating #{title} (#{gov_delivery_id}) in GovDelivery"
        begin
          Services.gov_delivery.create_topic(title, gov_delivery_id)
        rescue GovDelivery::Client::TopicAlreadyExistsError
          retry_create << [gov_delivery_id, title]
          logger.warn "-- Error Creating #{title} (#{gov_delivery_id}) in GovDelivery as delete has not completed"
        end
      end
      retry_create
    end
  end
end
