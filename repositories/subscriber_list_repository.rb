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
      .find_by(namespace, :tags, tags)
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

    # The storage adapters return hashes with symbol keys
    # Fortunately Struct#to_h returns symbol keys
    def dump(subscriber_list)
      subscriber_list
        .to_h
        .merge(
          created_at: subscriber_list.created_at.utc,
        )
    end

    # The storage adapters return hashes with symbol keys
    # We expect string keys throughout the application
    def load(persisted_data)
      deserialized_tags = json_load_hash_values(persisted_data.fetch(:tags))
      created_at = persisted_data.fetch(:created_at).utc

      loaded_data = persisted_data
        .merge(
          created_at: created_at,
          tags: deserialized_tags,
        )

      factory.call(loaded_data)
    end

  private

    attr_reader :factory

    def json_load_hash_values(hash)
      hash.reduce({}) { |result, (k, v)|
        result.merge(k => JSON.load(v))
      }
    end
  end
end
