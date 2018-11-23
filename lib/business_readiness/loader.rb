require "csv"

module BusinessReadiness
  class Loader
    def initialize(filename, facets_filename)
      @rows = CSV.read(filename, converters: lambda { |v| v || "" })
      @facets = {}

      if File.exist?(facets_filename)
        facet_config = YAML.load_file(facets_filename)
        @facets = facet_config["details"]["facets"]
      end
    end

    def base_paths_with_tags
      rows.each_with_object({}) do |row, hash|
        base_path = row[0]

        tags = tags_for_row(row)
        tags["appear_in_find_eu_exit_guidance_business_finder"] = "yes"

        hash[base_path] = tags
      end
    end

  private

    attr_reader :facets, :rows

    def tags_for_row(row)
      if row[1].strip == "yes"
        create_all_tags
      else
        specific_tags(row)
      end
    end

    def create_all_tags
      facets.each_with_object({}) do |facet, tags|
        tags[facet["key"]] = facet["allowed_values"].map { |f| f["value"] }
      end
    end

    def specific_tags(row)
      tags = {}
      facets.each_with_index do |facet, index|
        row_index = index + 2
        tags[facet["key"]] = row.fetch(row_index, "").split(",").map(&:strip)
      end

      tags.reject do |_, value|
        value == []
      end
    end
  end
end
