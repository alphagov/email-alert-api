require_relative "configuration"
require "core_ext"
require "create_topic"
require "processible_input_filter"
require "unique_tag_set_filter"
require "topic_persistence_aspect"
require "ostruct"

class Application
  def initialize(
    storage_adapter: default_storage_adapter,
    gov_delivery_client: default_gov_delivery_client
  )
    @storage_adapter = storage_adapter
    @gov_delivery_client = gov_delivery_client
  end

  def create_topic(context)
    processible_input_filter(
      unique_tag_set_filter(
        topic_persistence_aspect(
          create_topic_service
        )
      )
    ).call(context)
  end

  private

  attr_reader(
    :storage_adapter,
    :gov_delivery_client,
  )

  class Thing < OpenStruct
    def to_json(*args, &block)
      to_h.to_json(*args, &block)
    end
  end

  def processible_input_filter(service)
    ->(context) {
      ProcessibleInputFilter.new(
        title: context.params.fetch("title", nil),
        tags: context.params.fetch("tags", {}),
        context: context,
        service: service,
      ).call
    }
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

  def default_storage_adapter
    {}
  end

  def topics_repository
    @topics_repository ||= MemoryRepository.new(storage_adapter)
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
