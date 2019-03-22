require "csv"

module BusinessReadiness
  class Loader
    def initialize(filename)
      @rows = CSV.read(filename, converters: lambda { |v| v || "" })
    end

    def base_paths_with_tags
      rows.each_with_object({}) do |row, hash|
        base_path = row[0]

        tags = {}
        tags["appear_in_find_eu_exit_guidance_business_finder"] = "yes"

        hash[base_path] = tags
      end
    end

  private

    attr_reader :rows
  end
end
