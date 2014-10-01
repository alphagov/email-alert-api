require "spec_helper"

require "subscriber_list_tag_searcher"

RSpec.describe SubscriberListTagSearcher do
  subject(:matcher) {
    SubscriberListTagSearcher.new(
      publication_tags: publication_tags,
      subscriber_lists: subscriber_lists,
    )
  }

  let(:publication_tags) {
    {
      "document_type" => %w(cma_case),
      "case_type" => %w(markets mergers),
      "market_sector" => %w(oil-and-gas),
    }
  }

  context "subscriber_lists with single tags and single values" do
    let(:all_cma_cases_subscriber_list) {
      double(
        :all_cma_cases_subscriber_list,
        tags: {
          "document_type" => ["cma_case"],
        },
      )
    }

    let(:all_aaib_reports_subscriber_list) {
      double(
        :all_aaib_reports_subscriber_list,
        tags: {
          "document_type" => ["aaib_report"],
        },
      )
    }

    let(:subscriber_lists) {
      [
        all_cma_cases_subscriber_list,
        all_aaib_reports_subscriber_list,
      ]
    }

    it "matches subscriber_lists where the single tag and value matches" do
      expect(matcher.matching_subscriber_lists).to match_array([
        all_cma_cases_subscriber_list,
      ])
    end
  end

  context "subscriber_lists with multiple tags and single values" do
    let(:cma_cases_about_oil_and_gas_subscriber_list) {
      double(
        :cma_cases_about_oil_and_gas_subscriber_list,
        tags: {
          "document_type" => ["cma_case"],
          "market_sector" => %w(oil-and-gas),
        },
      )
    }

    let(:cma_cases_about_energy_subscriber_list) {
      double(
        :cma_cases_about_energy_subscriber_list,
        tags: {
          "document_type" => ["cma_case"],
          "market_sector" => %w(energy),
        },
      )
    }

    let(:subscriber_lists) {
      [
        cma_cases_about_oil_and_gas_subscriber_list,
        cma_cases_about_energy_subscriber_list,
      ]
    }

    it "matches subscriber_lists where all tags match the corresponding value" do
      expect(matcher.matching_subscriber_lists).to match_array([
        cma_cases_about_oil_and_gas_subscriber_list
      ])
    end
  end

  context "subscriber_lists with single tags and multiple values" do
    let(:oil_and_gas_and_energy_subscriber_list) {
      double(
        :oil_and_gas_and_energy_subscriber_list,
        tags: {
          "market_sector" => %w(oil-and-gas energy),
        },
      )
    }

    let(:chemicals_and_energy_subscriber_list) {
      double(
        :chemicals_and_energy_subscriber_list,
        tags: {
          "market_sector" => %w(chemicals energy),
        },
      )
    }

    let(:oil_and_gas_and_chemicals_subscriber_list) {
      double(
        :oil_and_gas_and_chemicals_subscriber_list,
        tags: {
          "market_sector" => %w(oil-and-gas chemicals),
        },
      )
    }

    let(:subscriber_lists) {
      [
        oil_and_gas_and_energy_subscriber_list,
        chemicals_and_energy_subscriber_list,
        oil_and_gas_and_chemicals_subscriber_list,
      ]
    }

    it "matches subscriber_lists where any of the tag values matches the publication" do
      expect(matcher.matching_subscriber_lists).to match_array([
        oil_and_gas_and_energy_subscriber_list,
        oil_and_gas_and_chemicals_subscriber_list,
      ])
    end
  end

  context "subscriber_lists matching case_type (which has multiple values)" do
    let(:consumer_enforcement_and_criminal_cartels_subscriber_list) {
      double(
        :consumer_enforcement_and_criminal_cartels_subscriber_list,
        tags: {
          "case_type" => %w(consumer-enforcement criminal-cartels),
        }
      )
    }

    let(:consumer_enforcement_and_markets_subscriber_list) {
      double(
        :consumer_enforcement_and_markets_subscriber_list,
        tags: {
          "case_type" => %w(consumer-enforcement markets),
        }
      )
    }

    let(:markets_and_mergers_subscriber_list) {
      double(
        :markets_and_mergers_subscriber_list,
        tags: {
          "case_type" => %w(mergers markets),
        }
      )
    }

    let(:subscriber_lists) {
      [
        consumer_enforcement_and_criminal_cartels_subscriber_list,
        consumer_enforcement_and_markets_subscriber_list,
        markets_and_mergers_subscriber_list,
      ]
    }

    it "matches on either or both values of the publication's tag" do
      expect(matcher.matching_subscriber_lists).to match_array([
        consumer_enforcement_and_markets_subscriber_list,
        markets_and_mergers_subscriber_list,
      ])
    end
  end

  context "subscriber_lists matching specialist_subscriber_list (which publication doesn't have)" do
    let(:general_aviation_fixed_wing_subscriber_list) {
      double(
        :general_aviation_fixed_wing_subscriber_list,
        tags: {
          "aircraft_category" => %w(general-aviation-fixed-wing),
        },
      )
    }

    let(:subscriber_lists) {
      [
        general_aviation_fixed_wing_subscriber_list,
      ]
    }

    it "does not match subscriber_lists with tags not present in the publication" do
      expect(matcher.matching_subscriber_lists).to match_array([])
    end
  end
end
