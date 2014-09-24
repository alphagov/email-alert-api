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
    adapter.store(key, dump(entity))
  end

  def find_by_tags(tags)
    adapter
      .find_by(:tags, tags)
      .map { |_id, topic_data|
        load(topic_data)
      }
  end

private
  attr_reader(
    :adapter,
    :factory,
  )

  def load(datum)
    factory.call(
      datum
    )
  end

  def dump(entity)
    entity.to_h
  end
end
