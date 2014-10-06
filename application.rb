# Application essentials
require_relative "config/env"
require "core_ext"

# Application components (alphabetical please)
require "create_subscriber_list"
require "notify_subscriber_lists"
require "postgres_adapter"
require "search_subscriber_list_by_tag"
require "string_param_validator"
require "subscriber_list_persistence_aspect"
require "subscriber_list_repository"
require "subscriber_list_search_aspect"
require "subscriber_list_tag_searcher"
require "tag_set_domain_aspect"
require "tag_set"
require "tags_param_validator"
require "unique_tag_set_filter"
require "valid_input_filter"

class Application
  def initialize(
    config:,
    storage_adapter:,
    gov_delivery_client:,
    uuid_generator:
  )
    @config = config
    @storage_adapter = storage_adapter
    @gov_delivery_client = gov_delivery_client
    @uuid_generator = uuid_generator
  end

  def create_subscriber_list(context)
    valid_create_subscriber_list_input_filter(
      tag_set_domain_aspect(
        unique_tag_set_filter(
          subscriber_list_persistence_aspect(
            create_subscriber_list_service
          )
        )
      )
    ).call(context)
  end

  def search_subscriber_lists(context)
    # TODO: Express somehow that in this case tags must be an exact match
    valid_search_subscriber_lists_input_filter(
      tag_set_domain_aspect(
        search_subscriber_list_by_tags_service
      )
    ).call(context)
  end

  def notify_subscriber_lists_by_tags(context)
    # TODO: Express somehow that in this case publication tags fuzzy match a
    # number of subscriber lists
    valid_notify_subscriber_lists_input_filter(
      tag_searcher(
        notify_subscriber_lists_service
      )
    ).call(context)
  end

  private

  attr_reader(
    :config,
    :storage_adapter,
    :gov_delivery_client,
    :uuid_generator,
  )

  require "ostruct"
  class SubscriberList < OpenStruct
    def to_json(*args, &block)
      to_h.to_json(*args, &block)
    end
  end

  def tag_set_domain_aspect(service)
    ->(context) {
      TagSetDomainAspect.new(
        factory: tag_set_factory,
        service: service,
        context: context,
        tags: context.params.fetch("tags"),
      ).call
    }
  end

  def valid_create_subscriber_list_input_filter(service)
    ->(context) {
      ValidInputFilter.new(
        validators: [
          TagsParamValidator.new(context.params.fetch("tags", nil)),
          StringParamValidator.new(context.params.fetch("title", nil)),
        ],
        service: service,
        context: context,
      ).call
    }
  end

  def valid_search_subscriber_lists_input_filter(service)
    ->(context) {
      ValidInputFilter.new(
        validators: [
          TagsParamValidator.new(context.params.fetch("tags", nil)),
        ],
        service: service,
        context: context,
      ).call
    }
  end

  def valid_notify_subscriber_lists_input_filter(service)
    ->(context) {
      ValidInputFilter.new(
        validators: [
          TagsParamValidator.new(context.params.fetch("tags", nil)),
          StringParamValidator.new(context.params.fetch("subject", nil)),
          StringParamValidator.new(context.params.fetch("body", nil)),
        ],
        service: service,
        context: context,
      ).call
    }
  end

  def tag_searcher(service)
    ->(context) {
      SubscriberListSearchAspect.new(
        repo: subscriber_list_repository,
        subscriber_list_searcher: subscriber_list_searcher,
        service: notify_subscriber_lists_service,
        context: context,
        tags: context.params.fetch("tags"),
      ).call
    }
  end

  def unique_tag_set_filter(service)
    ->(context, tags: tags) {
      UniqueTagSetFilter.new(
        repo: subscriber_list_repository,
        tags: tags,
        context: context,
        service: service,
      ).call
    }
  end

  def subscriber_list_persistence_aspect(service)
    ->(context) {
      SubscriberListPersistenceAspect.new(
        context: context,
        repo: subscriber_list_repository,
        service: service,
      ).call
    }
  end

  def create_subscriber_list_service
    ->(context) {
      CreateSubscriberList.new(
        context: context,
        subscriber_list_attributes: context.params.slice("title", "tags"),
        gov_delivery_client: gov_delivery_client,
        subscriber_list_builder: subscriber_list_builder,
        subscription_link_template: subscription_link_template,
      ).call
    }
  end

  def search_subscriber_list_by_tags_service
    ->(context, tags:) {
      SearchSubscriberListByTags.new(
        repo: subscriber_list_repository,
        context: context,
        tags: tags,
      ).call
    }
  end

  def notify_subscriber_lists_service
    ->(subscriber_lists, context) {
      NotifySubscriberLists.new(
        gov_delivery_client: gov_delivery_client,
        context: context,
        subject: context.params.fetch("subject"),
        body: context.params.fetch("body"),
        subscriber_lists: subscriber_lists,
      ).call
    }
  end

  def subscriber_list_repository
    @subscriber_list_repository ||= SubscriberListRepository.new(
      adapter: storage_adapter,
      factory: subscriber_list_factory,
    )
  end

  def tag_set_factory
    TagSet.method(:new)
  end

  def subscriber_list_builder
    ->(attributes) {
      subscriber_list_factory.call(
        attributes.merge(
          id: uuid_generator.call,
        )
      )
    }
  end

  def subscriber_list_factory
    SubscriberList.method(:new)
  end

  def subscriber_list_searcher
    ->(publication_tags:, search_subscriber_lists:) {
      SubscriberListTagSearcher
        .new(publication_tags: publication_tags, subscriber_lists: search_subscriber_lists)
        .subscriber_lists
    }
  end

  def subscription_link_template
    config.fetch(:gov_delivery).fetch(:subscription_link_template)
  end
end
