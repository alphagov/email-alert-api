class TopicRepository
  def initialize(adapter:, factory:)
    @adapter = adapter
    @factory = factory
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
    :factory,
  )

  def load(data)
    factory.call(data)
  end

  def dump(entity)
    entity.to_h
  end

  def namespace
    :topics
  end
end
