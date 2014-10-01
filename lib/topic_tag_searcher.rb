class TopicTagSearcher
  def initialize(publication_tags:, search_topics:)
    @publication_tags = publication_tags
    @search_topics = search_topics
  end

  attr_reader(
    :search_topics,
    :publication_tags,
  )

  # TODO: With current data this is expected to take between 50-200ms
  #       This may need optimisation when we have an adaquate dataset.
  def topics
    search_topics.select { |topic|
      publication_matches_all_topic_tags_on_at_least_one_value(topic.tags)
    }
  end

  private

  def publication_matches_all_topic_tags_on_at_least_one_value(topic_tags)
    topic_tags.all? { |tag_name, topic_tag_values|
      has_intersection?(topic_tag_values, publication_tag_values(tag_name))
    }
  end

  def has_intersection?(a, b)
    (a & b).size > 0
  end

  def publication_tag_values(tag_name)
    publication_tags.fetch(tag_name, [])
  end
end
