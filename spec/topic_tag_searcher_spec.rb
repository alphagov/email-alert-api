require "spec_helper"

require "topic_tag_searcher"

RSpec.describe TopicTagSearcher do
  subject(:matcher) {
    TopicTagSearcher.new(
      publication_tags: publication_tags,
      search_topics: search_topics,
    )
  }

  let(:publication_tags) {
    {
      "document_type" => %w(cma_case),
      "case_type" => %w(markets mergers),
      "market_sector" => %w(oil-and-gas),
    }
  }

  context "topics with single tags and single values" do
    let(:all_cma_cases_topic) {
      double(
        :all_cma_cases_topic,
        tags: {
          "document_type" => ["cma_case"],
        },
      )
    }

    let(:all_aaib_reports_topic) {
      double(
        :all_aaib_reports_topic,
        tags: {
          "document_type" => ["aaib_report"],
        },
      )
    }

    let(:search_topics) {
      [
        all_cma_cases_topic,
        all_aaib_reports_topic,
      ]
    }

    it "matches topics where the single tag and value matches" do
      expect(matcher.topics).to match_array([
        all_cma_cases_topic,
      ])
    end
  end

  context "topics with multiple tags and single values" do
    let(:cma_cases_about_oil_and_gas_topic) {
      double(
        :cma_cases_about_oil_and_gas_topic,
        tags: {
          "document_type" => ["cma_case"],
          "market_sector" => %w(oil-and-gas),
        },
      )
    }

    let(:cma_cases_about_energy_topic) {
      double(
        :cma_cases_about_energy_topic,
        tags: {
          "document_type" => ["cma_case"],
          "market_sector" => %w(energy),
        },
      )
    }

    let(:search_topics) {
      [
        cma_cases_about_oil_and_gas_topic,
        cma_cases_about_energy_topic,
      ]
    }

    it "matches topics where all tags match the corresponding value" do
      expect(matcher.topics).to match_array([
        cma_cases_about_oil_and_gas_topic
      ])
    end
  end

  context "topics with single tags and multiple values" do
    let(:oil_and_gas_and_energy_topic) {
      double(
        :oil_and_gas_and_energy_topic,
        tags: {
          "market_sector" => %w(oil-and-gas energy),
        },
      )
    }

    let(:chemicals_and_energy_topic) {
      double(
        :chemicals_and_energy_topic,
        tags: {
          "market_sector" => %w(chemicals energy),
        },
      )
    }

    let(:oil_and_gas_and_chemicals_topic) {
      double(
        :oil_and_gas_and_chemicals_topic,
        tags: {
          "market_sector" => %w(oil-and-gas chemicals),
        },
      )
    }

    let(:search_topics) {
      [
        oil_and_gas_and_energy_topic,
        chemicals_and_energy_topic,
        oil_and_gas_and_chemicals_topic,
      ]
    }

    it "matches topics where any of the tag values matches the publication" do
      expect(matcher.topics).to match_array([
        oil_and_gas_and_energy_topic,
        oil_and_gas_and_chemicals_topic,
      ])
    end
  end

  context "topics matching case_type (which has multiple values)" do
    let(:consumer_enforcement_and_criminal_cartels_topic) {
      double(
        :consumer_enforcement_and_criminal_cartels_topic,
        tags: {
          "case_type" => %w(consumer-enforcement criminal-cartels),
        }
      )
    }

    let(:consumer_enforcement_and_markets_topic) {
      double(
        :consumer_enforcement_and_markets_topic,
        tags: {
          "case_type" => %w(consumer-enforcement markets),
        }
      )
    }

    let(:markets_and_mergers_topic) {
      double(
        :markets_and_mergers_topic,
        tags: {
          "case_type" => %w(mergers markets),
        }
      )
    }

    let(:search_topics) {
      [
        consumer_enforcement_and_criminal_cartels_topic,
        consumer_enforcement_and_markets_topic,
        markets_and_mergers_topic,
      ]
    }

    it "matches on either or both values of the publication's tag" do
      expect(matcher.topics).to match_array([
        consumer_enforcement_and_markets_topic,
        markets_and_mergers_topic,
      ])
    end
  end

  context "topics matching specialist_topic (which publication doesn't have)" do
    let(:general_aviation_fixed_wing_topic) {
      double(
        :general_aviation_fixed_wing_topic,
        tags: {
          "aircraft_category" => %w(general-aviation-fixed-wing),
        },
      )
    }

    let(:search_topics) {
      [
        general_aviation_fixed_wing_topic,
      ]
    }

    it "does not match topics with tags not present in the publication" do
      expect(matcher.topics).to match_array([])
    end
  end
end
