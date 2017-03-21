class FindExactMatch
  def initialize(query_field: :tags)
    raise ArgumentError.new("query_field must be `:tags` or `:links`") unless %i{tags links}.include?(query_field)

    @query_field = query_field.to_sym
  end


  def call(query_hash, document_type)
    return [] unless query_hash.present?

    subscriber_lists = subscriber_lists_where_all_keys_present(query_hash)
    subscriber_lists = subscriber_lists.where(document_type: document_type)

    subscriber_lists.select do |list|
      list.send(@query_field).all? do |descriptor, array_of_values|
        next if query_hash[descriptor].nil?
        query_hash[descriptor].sort == array_of_values.sort
      end
    end
  end

private

  # Return all SubscriberLists which are marked with all of the same link types
  # as those requested.  For example, if `links` is:
  #
  #     {"topics": [...], "organisations": [...]}
  #
  # then this returns all lists which have any "topics" AND "organisations"
  # links.
  def subscriber_lists_where_all_keys_present(query_hash)
    # This uses array equality to check if the JSON object
    # contains all the specified keys.
    SubscriberList.where("ARRAY(SELECT json_object_keys(#{@query_field})) = Array[:keys]",
      keys: query_hash.keys,
    )
  end
end
