class SubscriberListRepository
  def initialize(adapter:, factory:)
    @adapter = adapter
    @mapper = Mapper.new(factory)
  end

  def all
    adapter.all(namespace)
      .map(&method(:load))
  end

  def fetch(key)
    load(
      adapter.fetch(key)
    )
  end

  def store(key, entity)
    adapter.store(namespace, key, dump(entity))
  end

  # TODO: find_by_exact_tags?
  def find_by_tags(tags)
    adapter
      .find_by(namespace, :tags, mapper.dump_hash_values(tags))
      .map(&method(:load))
  end

private
  attr_reader(
    :adapter,
    :mapper,
  )

  def load(data)
    mapper.load(data)
  end

  def dump(entity)
    mapper.dump(entity)
  end

  def namespace
    :subscriber_lists
  end

  class Mapper
    def initialize(factory)
      @factory = factory
    end

    def dump(subscriber_list)
      serialized_tags = dump_hash_values(subscriber_list.tags)

      subscriber_list
        .to_h
        .merge(
          tags: serialized_tags,
          created_at: subscriber_list.created_at.utc,
        )
    end

    def load(persisted_data)
      deserialized_tags = load_hash_values(persisted_data.fetch(:tags))
      created_at = persisted_data.fetch(:created_at).utc

      loaded_data = persisted_data
        .merge(
          tags: deserialized_tags,
          created_at: created_at,
        )

      factory.call(loaded_data)
    end

    def dump_hash_values(hash)
      hash.reduce({}) { |result, (k, v)|
        result.merge(k => JSON.dump(v))
      }
    end

    def load_hash_values(hash)
      hash.reduce({}) { |result, (k, v)|
        result.merge(k => JSON.load(v))
      }
    end

  private

    attr_reader :factory
  end
end
