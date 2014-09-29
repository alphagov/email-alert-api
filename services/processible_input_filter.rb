class ProcessibleInputFilter
  def initialize(service:, context:, title:, tags:)
    @service = service
    @context = context
    @title = title
    @tags = tags
  end

  def call
    if processible_request?
      service.call(context)
    else
      context.unprocessible(error: error_message)
    end
  end

private

  attr_reader(
    :service,
    :context,
    :title,
    :tags,
  )

  def processible_request?
    valid_title? && valid_tag_structure?
  end

  def valid_title?
    !title.nil? && !title.empty?
  end

  def valid_tag_structure?
    if tags.empty? || !tags.is_a?(Hash) || !all_tags_are_arrays?
      false
    else
      true
    end
  end

  def all_tags_are_arrays?
    tags.values.all? { |v| v.is_a?(Array) }
  end

  def error_message
    "A topic was not created due to an invalid attributes"
  end
end
