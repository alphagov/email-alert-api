class MatchedForNotification
  def initialize(query_field: :tags, scope: SubscriberList)
    raise ArgumentError.new("query_field must be `:tags` or `:links`") unless %i{tags links}.include?(query_field)

    @query_field = query_field.to_sym
    @scope = scope
  end

  # Filter out subscriber lists:
  # - where the keys from the supplied hash:
  #   - Have a superset of the keys in the specified query_field for subscriber_lists
  #   - Have an overlap with  the keys in the specified query_field for or_joined_facet_subscriber_lists
  # - AND
  # - If the operator is 'any':
  #     the key values in the subscriber list have at least one corresponding match in the supplied hash.
  # - If the operator is 'all'
  #   all key values in the subscriber list have corresponding matches in the supplied hash.
  def call(content_item_tags_or_links)
    return [] unless content_item_tags_or_links.present?

    content_item_tags_or_links = content_item_tags_or_links.deep_symbolize_keys

    only_contains_keys(content_item_tags_or_links.keys).select do |subscriber_list|
      filter_tags_or_links(subscriber_list, content_item_tags_or_links)
    end
  end

private

  def filter_tags_or_links(subscriber_list, content_item_tags_or_links)
    operator = subscriber_list.type == 'OrJoinedFacetSubscriberList' ? :any? : :all?
    subscriber_list_tags_or_links = subscriber_list.send(@query_field) # send ensures the keys are symbols
    subscriber_list_tags_or_links.keys.send(operator) do |key|
      content_item_values = Array(content_item_tags_or_links[key])
      any_values = subscriber_list_tags_or_links[key].fetch(:any, [])
      all_values = subscriber_list_tags_or_links[key].fetch(:all, [])

      (all_values - content_item_values).empty? &&
        (any_values.empty? || (any_values & content_item_values).any?)
    end
  end

  # Returns:
  #
  # all SubscriberLists which have a subset of keys from those requested.
  # For example, if `links` is:
  #
  #     {"topics": [...], "organisations": [...]}
  #
  # then this returns all lists which have only "topics" and/or "organisations"
  # links, but not those with "topics" and "policies"
  #
  # all OrJoinedFacetSubscriberLists which has an intersection of keys from those requested
  # For example, if `links` is:
  #
  #     {"topics": [...], "organisations": [...]}
  #
  # then this returns all lists which have "topics" and/or "organisations"
  # or "topics" and "policies"
  def only_contains_keys(keys)
    # This uses the <@` array operator, which returns true if the all the items in the left
    # side array are contained in the right side array
    @scope
      .where(type: ["", nil])
      .where("#{@query_field}::text != '{}'")
      .where("ARRAY(SELECT json_object_keys(#{@query_field})) <@ Array[:keys]",
             keys: keys,) +
    # This uses the &&` array operator, which returns true if there is an intersection between
    # the items in the left side array and those contained in the right side array
      @scope
          .where(type: "OrJoinedFacetSubscriberList")
          .where("#{@query_field}::text != '{}'")
          .where("ARRAY(SELECT json_object_keys(#{@query_field})) && Array[:keys]",
                 keys: keys,)
  end
end
