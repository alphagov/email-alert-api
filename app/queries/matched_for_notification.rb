class MatchedForNotification
  def initialize(query_field: :tags, scope: SubscriberList)
    raise ArgumentError.new("query_field must be `:tags` or `:links`") unless %i{tags links}.include?(query_field)

    @query_field = query_field.to_sym
    @scope = scope
  end

  # Filter out subscriber lists:
  # - where the keys from the supplied hash are a superset of the keys in the specified query_field AND
  # - the key values in the subscriber list have at least one corresponding match in the supplied hash.
  # Note that this means that not all keys from the the supplied hash are required to be matched.
  def call(content_item_tags_or_links)
    return [] unless content_item_tags_or_links.present?

    content_item_tags_or_links = content_item_tags_or_links.stringify_keys

    only_contains_keys(content_item_tags_or_links.keys).select do |subscriber_list|
      subscriber_list_tags_or_links = subscriber_list[@query_field]

      subscriber_list_tags_or_links.keys.all? do |key|
        (
          Array(content_item_tags_or_links[key]) & subscriber_list_tags_or_links[key]
        ).any?
      end
    end
  end

private

  # Return all SubscriberLists which have a subset of keys from those requested.
  # For example, if `links` is:
  #
  #     {"topics": [...], "organisations": [...]}
  #
  # then this returns all lists which have only "topics" and/or "organisations"
  # links, but not those with "topics" and "policies"
  def only_contains_keys(keys)
    # This uses the <@` array operator, which returns true if the all the items in the left
    # side array are contained in the right side array
    @scope
      .where("#{@query_field}::text != '{}'")
      .where("ARRAY(SELECT json_object_keys(#{@query_field})) <@ Array[:keys]",
        keys: keys,)
  end
end
