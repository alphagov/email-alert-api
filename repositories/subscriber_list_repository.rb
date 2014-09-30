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

    def dump(subscriber_list)
      subscriber_list.to_h
    end

    def load(data)
      deserialized_tags = data.fetch(:tags).reduce({}) { |result, (k, v)|
        result.merge(k => JSON.load(v))
      }

      factory.call(data.merge(
        tags: deserialized_tags,
      ))
    end

  private

    attr_reader :factory
  end
end
