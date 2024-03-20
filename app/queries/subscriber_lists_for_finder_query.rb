class SubscriberListsForFinderQuery
  attr_reader :govuk_path

  class NotAFinderError < StandardError; end

  def initialize(govuk_path:)
    @govuk_path = govuk_path
  end

  SELECT_FOR_TAGS_TEMPLATE = <<-SQL.freeze
    SELECT EXISTS (
      SELECT formats FROM (
        SELECT json_array_elements_text(tags -> ? -> 'any') AS formats
      ) AS allowed_formats WHERE formats = ?
    )
  SQL

  def call
    content_item = GdsApi.content_store.content_item(govuk_path).to_hash
    raise NotAFinderError unless content_item["document_type"] == "finder"

    lists = []
    content_item["details"]["filter"].each_key do |filter_name|
      Array(content_item["details"]["filter"][filter_name]).each do |filter_value|
        lists += SubscriberList.where(SELECT_FOR_TAGS_TEMPLATE, filter_name, filter_value)
      end
    end

    lists.uniq
  end
end
