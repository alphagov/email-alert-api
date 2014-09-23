require_relative "configuration"
require "core_ext"
require "create_topic"
require "unique_topic_filter"

class Application
  def initialize(gov_delivery_client: default_gov_delivery_client)
    @gov_delivery_client = gov_delivery_client
  end

  def create_topic(context)
    TopicPersistenceAspect.new(
      context: context,
      repo: topics,
      service: create_topic_service,
    ).call
  end

  private

  attr_reader :gov_delivery_client

  class Thing < OpenStruct
    def to_json(*args, &block)
      to_h.to_json(*args, &block)
    end
  end

  def create_topic_service
    ->(context) {
      CreateTopic.new(
        context: context,
        topic_attributes: context.params.slice("title", "tags"),
        gov_delivery_client: gov_delivery_client,
        topic_factory: Thing.method(:new),
      ).call
    }
  end

  def default_gov_delivery_client
    GovDeliveryClient.create_client(GOVDELIVERY_CREDENTIALS)
  end

  def topics_repository
    @topics_repository ||= MemoryRepository.new
  end

  require "forwardable"
  class MemoryRepository
    extend Forwardable
    def_delegators :@storage, :store, :fetch

    def initialize(storage = {})
      @storage = storage
    end

    def find_by_tags(tags)
      # go get some stuff out
    end

  private
    attr_reader(
      :storage,
    )
  end
end
