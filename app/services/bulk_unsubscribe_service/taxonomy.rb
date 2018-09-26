module BulkUnsubscribeService
  class Taxonomy
    def initialize
      @first_level_taxons = JSON.parse(Redis.current.get('topic_taxonomy_taxons'))
      @second_level_taxons = @first_level_taxons.flat_map { |t| t.dig('links', 'child_taxons') || [] }
    end

    def get_taxon_content_id(base_path)
      level_one_base_path = /\/[^\/]*/.match(base_path).to_s
      @first_level_taxons.find(-> { {} }) { |t| t['base_path'] == level_one_base_path }.fetch('content_id', 'all')
    end

    def get_subtaxon_content_id(base_path)
      @second_level_taxons.find(-> { {} }) { |t| t['base_path'] == base_path }.fetch('content_id', 'all')
    end
  end
end
