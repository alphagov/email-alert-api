require "csv"

module BusinessReadiness
  class Loader
    def initialize(filename)
      @rows = CSV.read(filename)
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

    attr_reader :rows

    def tags_for_row(row)
      if row[1] == "yes"
        create_all_tags
      else
        specific_tags(row)
      end
    end

    def create_all_tags
      {
        "sector_business_area" => all_sector_business_area,
        "employ_eu_citizens" => all_employ_eu_citizens,
        "doing_business_in_the_eu" => all_doing_business_in_the_eu,
        "regulations_and_standards" => all_regulations_and_standards,
        "personal_data" => all_personal_data,
        "intellectual_property" => all_intellectual_property,
        "receiving_eu_funding" => all_receiving_eu_funding,
        "public_sector_procurement" => all_public_sector_procurement
      }
    end

    def specific_tags(row)
      {
        "sector_business_area" => row.fetch(2, "").split(","),
        "employ_eu_citizens" => row.fetch(3, "").split(","),
        "doing_business_in_the_eu" => row.fetch(4, "").split(","),
        "regulations_and_standards" => row.fetch(5, "").split(","),
        "personal_data" => row.fetch(6, "").split(","),
        "intellectual_property" => row.fetch(7, "").split(","),
        "receiving_eu_funding" => row.fetch(8, "").split(","),
        "public_sector_procurement" => row.fetch(9, "").split(",")
      }.reject do |_, value|
        value == []
      end
    end

    def all_sector_business_area
      [
        "accommodation-restaurants-and-catering-services",
        "aerospace",
        "agriculture",
        "air-transport-aviation",
        "ancillary-services",
        "animal-health",
        "automotive",
        "banking-market-infrastructure",
        "broadcasting",
        "chemicals",
        "computer-services",
        "construction-contracting",
        "education",
        "electricity",
        "electronics",
        "environmental-services",
        "fisheries",
        "food-and-drink",
        "furniture-and-other-manufacturing",
        "gas-markets",
        "goods-sectors-each-0-4-of-gva",
        "imports",
        "imputed-rent",
        "insurance",
        "land-transport-excl-rail",
        "medical-services",
        "motor-trades",
        "network-industries-0-3-of-gva",
        "oil-and-gas-production",
        "other-personal-services",
        "parts-and-machinery",
        "pharmaceuticals",
        "post",
        "professional-and-business-services",
        "public-administration-and-defence",
        "rail",
        "real-estate-excl-imputed-rent",
        "retail",
        "service-sectors-each-1-of-gva",
        "social-work",
        "steel-and-other-metals-commodities",
        "telecoms",
        "textiles-and-clothing",
        "top-ten-trade-partners-by-value",
        "warehousing-and-support-for-transportation",
        "water-transport-maritime-ports",
        "wholesale-excl-motor-vehicles"
      ]
    end

    def all_employ_eu_citizens
      %w(yes no dont-know)
    end

    def all_doing_business_in_the_eu
      [
        "do-business-in-the-eu",
        "buying",
        "selling",
        "transporting",
        "other-eu",
        "other-rest-of-the-world"
      ]
    end

    def all_regulations_and_standards
      %w(products-or-goods)
    end

    def all_personal_data
      [
        "processing-personal-data",
        "interacting-with-eea-website",
        "digital-service-provider"
      ]
    end

    def all_intellectual_property
      [
        "have-intellectual-property",
        "copyright",
        "trademarks",
        "designs",
        "patents",
        "exhaustion-of-rights"
      ]
    end

    def all_receiving_eu_funding
      [
        "horizon-2020",
        "cosme",
        "european-investment-bank-eib",
        "european-structural-fund-esf",
        "eurdf",
        "etcf",
        "esc",
        "ecp",
        "etf"
      ]
    end

    def all_public_sector_procurement
      [
        "civil-government-contracts",
        "defence-contracts"
      ]
    end
  end
end
