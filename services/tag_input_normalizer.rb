class TagInputNormalizer

  def initialize(service:, context:, tags:)
    @service = service
    @context = context
    @tags = tags
  end

  def call
    service.call(context, tags: normalized_tags)
  end

private
  attr_reader :service, :context, :tags

  def normalized_tags
    tags.reduce({}) { |result, (name, values)|
      result.merge(name => values.sort)
    }
  end
end
