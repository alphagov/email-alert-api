desc "Move all non-duplicated lists with the key :taxons in the link to an equivalent or new list containing :taxon_tree"
task move_taxons_to_taxon_tree: :environment do
  taxons_lists = SubscriberList.all.select { |list| list.links.key?(:taxons) }

  lists_without_matches = taxons_lists.select { |list| FindExactQuery.new(new_params(list)).exact_match.nil? }

  lists_without_matches.each do |from_list|
    from_list.links = updated_links(from_list)
    from_list.save!
    puts "Updated: #{from_list.slug}"
  end
end

def updated_links(list)
  list.links.transform_keys { |key| key == :taxons ? :taxon_tree : key }
end

def new_params(list)
  {
    tags: {},
    links: updated_links(list),
    document_type: list.document_type,
    email_document_supertype: list.email_document_supertype,
    government_document_supertype: list.government_document_supertype
  }
end
