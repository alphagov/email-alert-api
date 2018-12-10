class FindByTopic
  def initialize(query_field: :tags)
    raise ArgumentError.new("query_field must be `:tags` or `:links`") unless %i{tags links}.include?(query_field)

    @query_field = query_field.to_sym
  end

  def call(topic:)
    subscriber_lists_with_topics.select do |subscriber_list|
      subscriber_list.send(@query_field)[:topics][:any].include?(topic)
    end
  end

private

  def subscriber_lists_with_topics
    SubscriberList.where("(#{@query_field} -> 'topics') IS NOT NULL")
  end
end
