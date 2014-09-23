require_relative "configuration"
require "core_ext"
require "create_topic"
require "unique_tag_set_filter"
require "topic_persistence_aspect"

class Application
  def initialize(gov_delivery_client: default_gov_delivery_client)
    @gov_delivery_client = gov_delivery_client
  end

  def create_topic(context)
    unique_tag_set_filter(
      topic_persistence_aspect(
        create_topic_service
      )
    ).call(context)
  end

  private

  attr_reader :gov_delivery_client

  class Thing < OpenStruct
    def to_json(*args, &block)
      to_h.to_json(*args, &block)
    end
  end

  def unique_tag_set_filter(service)
    ->(context) {
      UniqueTagSetFilter.new(
        repo: topics_repository,
        tags: context.params.fetch("tags"),
        context: context,
        service: service,
      ).call
    }
  end

  def topic_persistence_aspect(service)
    ->(context) {
      TopicPersistenceAspect.new(
        context: context,
        repo: topics_repository,
        service: service,
      ).call
    }
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
      storage.select { |_id, topic|
        topic.tags == tags
      }
    end

  private
    attr_reader(
      :storage,
    )
  end
end
