class SubscriberListsByPathQuery
  attr_reader :govuk_path, :draft

  def initialize(govuk_path:, draft: false)
    @govuk_path = govuk_path
    @draft = draft
  end

  def call
    content_item = content_store_client.content_item(govuk_path).to_hash

    SubscriberListsByContentItemQuery.new(content_item).call
  end

private

  def content_store_client
    return GdsApi.content_store unless @draft

    # We don't appear to need a token for the #content_item method?
    GdsApi::ContentStore.new(Plek.find("draft-content-store"), bearer_token: "")
  end
end
