class SubscriberListsByPathQuery
  attr_reader :govuk_path, :draft

  def initialize(govuk_path:, draft: false)
    @govuk_path = govuk_path
    @draft = draft
  end

  def call
    content_item = content_store_client.content_item(govuk_path).to_hash

    SubscriberListQuery.new(
      content_id: content_item["content_id"],
      tags: tags_from_content_item(content_item),
      links: links_from_content_item(content_item),
      document_type: content_item["document_type"],
      email_document_supertype: supertypes(content_item)["email_document_supertype"],
      government_document_supertype: supertypes(content_item)["government_document_supertype"],
    ).lists
  end

private

  def content_store_client
    return GdsApi.content_store unless @draft

    # We don't appear to need a token for the #content_item method?
    GdsApi::ContentStore.new(Plek.find("draft-content-store"), bearer_token: "")
  end

  def supertypes(content_item)
    GovukDocumentTypes.supertypes(document_type: content_item["document_type"])
  end

  def tags_from_content_item(content_item)
    content_item["details"].fetch("tags", {}).merge(additional_items(content_item))
  end

  def links_from_content_item(content_item)
    compressed_links(content_item).merge(additional_items(content_item).merge("taxon_tree" => taxon_tree(content_item)))
  end

  def compressed_links(content_item)
    return {} unless content_item.key?("links")

    keys = (content_item["links"].keys || []) - %w[available_translations taxons]
    compressed_links = {}
    keys.each do |k|
      compressed_links[k] = content_item["links"][k].collect { |i| i["content_id"] }
    end
    compressed_links
  end

  def additional_items(content_item)
    { "content_store_document_type" => content_item["document_type"] }.merge(supertypes(content_item))
  end

  def taxon_tree(content_item)
    return [] unless content_item.key?("links")
    return [] unless content_item["links"].key?("taxons")
    return [] unless content_item["links"]["taxons"].any?

    [content_item["links"]["taxons"].first["content_id"]] + get_parent_links(content_item["links"]["taxons"].first)
  end

  def get_parent_links(taxon_struct)
    return [] unless taxon_struct.key?("links")
    return [] unless taxon_struct["links"].key?("parent_taxons")
    return [] unless taxon_struct["links"]["parent_taxons"].any?

    tree = []
    taxon_struct["links"]["parent_taxons"].each do |parent_taxon|
      tree += [parent_taxon["content_id"]]
      tree += get_parent_links(parent_taxon)
    end

    tree
  end
end
