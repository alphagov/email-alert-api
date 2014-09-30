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

  def find_by_tags(tags)
    adapter
      .find_by(namespace, :tags, tags)
      .map { |_id, topic_data|
        load(topic_data)
      }
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
      factory.call(data)
    end

  private

    attr_reader :factory
  end
end
