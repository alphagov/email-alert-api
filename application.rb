require_relative "config/env"
require "core_ext"
require "create_topic"
require "ostruct"
require "processable_input_filter"
require "notify_topics"
require "unique_tag_set_filter"
require "topic_persistence_aspect"
require "ostruct"
require "postgres_adapter"
require "topic_repository"
require "unique_tag_set_filter"

class Application
  def initialize(
    config:,
    storage_adapter: default_storage_adapter,
    gov_delivery_client: default_gov_delivery_client,
    uuid_generator: default_uuid_generator
  )
    @config = config
    @storage_adapter = storage_adapter
    @gov_delivery_client = gov_delivery_client
    @uuid_generator = uuid_generator
  end

  def create_topic(context)
    processable_input_filter(
      unique_tag_set_filter(
        topic_persistence_aspect(
          create_topic_service
        )
      )
    ).call(context)
  end

  def notify_topics_by_tags(context)
    notify_topics_service.call(context)
  end

  private

  attr_reader(
    :config,
    :storage_adapter,
    :gov_delivery_client,
    :uuid_generator,
  )

  class Topic < OpenStruct
    def to_json(*args, &block)
      to_h.to_json(*args, &block)
    end
  end

  def processable_input_filter(service)
    ->(context) {
      ProcessableInputFilter.new(
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
        topic_builder: topic_builder,
      ).call
    }
  end

  def notify_topics_service
    ->(context) {
      NotifyTopics.new(
        context: context,
        topics_repository: topics_repository,
        subject: context.params.fetch("subject"),
        body: context.params.fetch("body"),
        tags: context.params.fetch("tags"),
        gov_delivery_client: gov_delivery_client,
      ).call
    }
  end

  def default_gov_delivery_client
    GovDeliveryClient.create_client(GOVDELIVERY_CREDENTIALS)
  end

  def default_storage_adapter
    PostgresAdapter.new(
      config: config,
    )
  end

  def default_uuid_generator
    SecureRandom.method(:uuid)
  end

  def topics_repository
    @topics_repository ||= TopicRepository.new(
      adapter: storage_adapter,
      factory: topic_factory,
    )
  end

  def topic_builder
    ->(attributes) {
      topic_factory.call(
        attributes.merge(
          id: uuid_generator.call,
        )
      )
    }
  end

  def topic_factory
    Topic.method(:new)
  end
end
