class TopicRepository
  def initialize(adapter:, factory:)
    @adapter = adapter
    @mapper = Mapper.new(factory)
  end

  def fetch(key)
    load(
      adapter.fetch(key)
    )
  end

  def store(key, entity)
    attrs = dump(entity).except(:gov_delivery_id)

    adapter.store(namespace, key, attrs)
  end

  # TODO: find_by_exact_tags?
  def find_by_tags(tags)
    adapter
      .find_by(namespace, :tags, tags)
      .map(&method(:load))
  end

  def find_by_publications_tags(tags)
    adapter.all(namespace).map(&method(:load))
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
    :topics
  end

  class Mapper
    def initialize(factory)
      @factory = factory
    end

    def dump(topic)
      topic.to_h
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
