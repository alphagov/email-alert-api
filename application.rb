# Application essentials
require_relative "config/env"
require "core_ext"

# Application components (alphabetical please)
require "create_subscriber_list"
require "notify_subscriber_lists"
require "postgres_adapter"
require "responder_proxy"
require "search_subscriber_list_by_tag"
require "string_param_validator"
require "subscriber_list"
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
    clock:,
    uuid_generator:
  )
    @config = config
    @storage_adapter = storage_adapter
    @gov_delivery_client = gov_delivery_client
    @clock = clock
    @uuid_generator = uuid_generator
  end

  def create_subscriber_list(context)
    call_service(
      aspects: [
        :valid_create_subscriber_list_input_filter,
        :tag_set_domain_aspect,
        :unique_tag_set_filter,
        :subscriber_list_persistence_aspect,
      ],
      service: create_subscriber_list_service,
      context: context,
      arguments: %w(tags title),
    )
  end

  def search_subscriber_lists(context)
    call_service(
      aspects: [
        :valid_search_subscriber_lists_input_filter,
        :tag_set_domain_aspect,
      ],
      service: search_subscriber_list_by_tags_service,
      context: context,
      arguments: %w(tags),
    )
  end

  def notify_subscriber_lists_by_tags(context)
    call_service(
      aspects: [
        :valid_notify_subscriber_lists_input_filter,
        :tag_searcher,
      ],
      service: notify_subscriber_lists_service,
      context: context,
      arguments: %w(tags subject body)
    )
  end

  private

  attr_reader(
    :config,
    :storage_adapter,
    :gov_delivery_client,
    :uuid_generator,
    :clock,
  )

  MissingParameters = Class.new(StandardError)

  def call_service(service:, aspects:, context:, arguments: [])
    composed_service = aspects
      .reverse
      .map(&method(:method))
      .reduce(service) { |composed, aspect|
        aspect.call(composed)
      }

    composed_service.call(
      ResponderProxy.new(context.responder),
      **extract_context_params(context.params, arguments)
    )
  rescue MissingParameters
    context.responder.missing_parameters(
      error: "Request rejected due to invalid parameters"
    )
  end

  def missing_parameters
    raise MissingParameters
  end

  def extract_context_params(params, keys)
    string_keys = keys.map(&:to_s)

    string_keys
      .map { |key|
        [
          key,
          params.fetch(key) { missing_parameters },
        ]
      }
      .reduce({}) { |result, (k,v)|
        result.merge(k.to_sym => v)
      }
  end

  def compose_service(service, **collected_args)
    ->(responder, **more_args) {
      service.call(responder, **collected_args.merge(more_args))
    }
  end

  def tag_set_domain_aspect(service)
    ->(responder, tags:, **args) {
      TagSetDomainAspect.new(
        factory: tag_set_factory,
        service: compose_service(service, **args),
        responder: responder,
        tags: tags,
      ).call
    }
  end

  def valid_create_subscriber_list_input_filter(service)
    ->(responder, tags:, title:, **args) {
      ValidInputFilter.new(
        validators: [
          TagsParamValidator.new(tags),
          StringParamValidator.new(title),
        ],
        service: compose_service(service, tags: tags, title: title, **args),
        responder: responder,
      ).call
    }
  end

  def valid_search_subscriber_lists_input_filter(service)
    ->(responder, tags:, **args) {
      ValidInputFilter.new(
        validators: [
          TagsParamValidator.new(tags),
        ],
        service: compose_service(service, tags: tags, **args),
        responder: responder,
      ).call
    }
  end

  def valid_notify_subscriber_lists_input_filter(service)
    ->(responder, tags:, subject:, body:, **args) {
      ValidInputFilter.new(
        validators: [
          TagsParamValidator.new(tags),
          StringParamValidator.new(subject),
          StringParamValidator.new(body),
        ],
        service: compose_service(
          service,
          tags: tags,
          body: body,
          subject: subject,
          **args
        ),
        responder: responder,
      ).call
    }
  end

  def tag_searcher(service)
    ->(responder, tags:, **args) {
      SubscriberListSearchAspect.new(
        repo: subscriber_list_repository,
        subscriber_list_searcher: subscriber_list_searcher,
        service: compose_service(notify_subscriber_lists_service, **args),
        responder: responder,
        tags: tags,
      ).call
    }
  end

  def unique_tag_set_filter(service)
    ->(responder, tags:, **args) {
      UniqueTagSetFilter.new(
        repo: subscriber_list_repository,
        tags: tags,
        responder: responder,
        service: compose_service(service, **args),
      ).call
    }
  end

  def subscriber_list_persistence_aspect(service)
    ->(responder, **args) {
      SubscriberListPersistenceAspect.new(
        responder: responder,
        repo: subscriber_list_repository,
        service: compose_service(service, **args)
      ).call
    }
  end

  def create_subscriber_list_service
    ->(responder, tags:, title:) {
      CreateSubscriberList.new(
        responder: responder,
        gov_delivery_client: gov_delivery_client,
        subscriber_list_builder: subscriber_list_builder,
        subscription_link_template: subscription_link_template,
        title: title,
        tags: tags,
      ).call
    }
  end

  def search_subscriber_list_by_tags_service
    ->(responder, tags:) {
      SearchSubscriberListByTags.new(
        repo: subscriber_list_repository,
        responder: responder,
        tags: tags,
      ).call
    }
  end

  def notify_subscriber_lists_service
    ->(responder, subject:, body:, subscriber_lists:, **args) {
      NotifySubscriberLists.new(
        gov_delivery_client: gov_delivery_client,
        responder: responder,
        subject: subject,
        body: body,
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
          created_at: clock.call,
        )
      )
    }
  end

  def subscriber_list_factory
    ->(attributes) {
      SubscriberList.new(
        *SubscriberList.members.map { |member|
          attributes.fetch(member)
        }
      )
    }
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
