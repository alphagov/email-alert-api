require "rake"
require "rails_helper"
require "gds_api/test_helpers/publishing_api"

RSpec.describe "eu_exit_business_finder:update_subscriber_list_titles_and_facet_values" do
  include GdsApi::TestHelpers::PublishingApi

  before :each do
    Rails.application.load_tasks
  end

  def mock_facet_values_to_remove(values)
    allow(EuExitFacetMigrationConfig).to receive(:facet_values_to_remove).and_return(values)
  end

  def mock_facet_values_to_replace(replacements)
    allow(EuExitFacetMigrationConfig).to receive(:facet_values_to_replace).and_return(replacements)
  end

  def mock_facet_value_label_overrides(replacements)
    allow(EuExitFacetMigrationConfig).to receive(:facet_value_label_overrides).and_return(replacements)
  end

  let(:facet_values) { [] }
  let(:mock_behaviour!) {}
  let(:create_list_and_execute_rake!) {
    create(:subscriber_list, links: {
      facet_values: {
        any: facet_values,
      },
    })
    Rake::Task["eu_exit_business_finder:update_subscriber_list_titles_and_facet_values"].execute
  }

  describe "updating the facet values" do
    subject {
      stub_publishing_api_has_item("content_id" => "111-new")
      stub_publishing_api_has_item("content_id" => "222-new")
      stub_publishing_api_has_item("content_id" => "123-keep-me")
      mock_behaviour!
      create_list_and_execute_rake!
      SubscriberList.last.links[:facet_values][:any]
    }

    context "given values that should not be removed" do
      let(:facet_values) { %w[123-keep-me] }

      it { is_expected.to eql %w[123-keep-me] }
    end

    context "given only values to remove" do
      let(:facet_values) { %w[000-remove-me] }
      let(:mock_behaviour!) { mock_facet_values_to_remove(%w[000-remove-me]) }

      it { is_expected.to eql [] }
    end

    context "given a mixture of values to keep and remove" do
      let(:facet_values) { %w[123-keep-me 000-remove-me] }
      let(:mock_behaviour!) { mock_facet_values_to_remove(%w[000-remove-me]) }

      it { is_expected.to eql %w[123-keep-me] }
    end

    context "given values to replace" do
      let(:facet_values) { %w[000-old] }
      let(:mock_behaviour!) {
        mock_facet_values_to_replace("000-old" => %w[111-new])
      }

      it { is_expected.to eql %w[111-new] }
    end

    context "given a mixture of values to replace, remove and keep" do
      let(:facet_values) { %w[000-old 000-remove-me 123-keep-me] }
      let(:mock_behaviour!) {
        mock_facet_values_to_remove(%w[000-remove-me 000-old])
        mock_facet_values_to_replace("000-old" => %w[111-new])
      }

      it { is_expected.to eql %w[111-new 123-keep-me] }
    end

    context "given facet replacements which could lead to duplicates" do
      let(:facet_values) { %w[000-old 001-also-old] }
      let(:mock_behaviour!) {
        mock_facet_values_to_replace(
          "000-old" => "111-new",
          "001-also-old" => "111-new",
        )
      }

      it { is_expected.to eql %w[111-new] } # `111-new` should only appear once
    end

    context "given a facet value which has been split into multiple new facets" do
      let(:facet_values) { %w[000-old] }
      let(:mock_behaviour!) {
        mock_facet_values_to_replace(
          "000-old" => %w[111-new 222-new],
        )
      }

      it { is_expected.to eql %w[111-new 222-new] }
    end
  end

  describe "updating the title" do
    subject {
      stub_publishing_api_has_item(
        "content_id": "000-content-id-of-food-drink-tobacco-facet",
        "title": "Food, drink and tobacco (retail and wholesale)",
      )
      stub_publishing_api_has_item(
        "content_id": "111-content-id-of-ports-airports",
        "title": "Ports and airports",
      )
      stub_publishing_api_has_item(
        "content_id": "777-content-id-of-employing-eu-citizens",
        "title": "EU citizens",
      )
      stub_publishing_api_has_item(
        "content_id": "444-content-id-of-eu-funding",
        "title": "EU funding",
      )
      mock_behaviour!
      create_list_and_execute_rake!
      SubscriberList.last.title
    }

    context "build title from single facet value" do
      let(:facet_values) { %w[000-content-id-of-food-drink-tobacco-facet] }

      it {
        is_expected.to eql "EU Exit guidance for your business in the following category: 'Food, drink and tobacco (retail and wholesale)'"
      }
    end

    context "build title from multiple facet values" do
      let(:facet_values) { %w[000-content-id-of-food-drink-tobacco-facet 111-content-id-of-ports-airports] }

      it {
        is_expected.to eql "EU Exit guidance for your business in the following categories: 'Food, drink and tobacco (retail and wholesale)', 'Ports and airports'"
      }
    end

    context "build title from facet value whose title has been overridden" do
      let(:facet_values) { %w[000-content-id-of-food-drink-tobacco-facet] }
      let(:mock_behaviour!) {
        mock_facet_value_label_overrides(
          "000-content-id-of-food-drink-tobacco-facet" => "Special category",
        )
      }

      it { is_expected.to eql "EU Exit guidance for your business in the following category: 'Special category'" }
    end

    context "build title from a mixture of facet values and overridden facet titles" do
      let(:facet_values) {
        %w[
          000-content-id-of-food-drink-tobacco-facet
          111-content-id-of-ports-airports
          777-content-id-of-employing-eu-citizens
          444-content-id-of-eu-funding
        ]
      }
      let(:mock_behaviour!) {
        mock_facet_value_label_overrides(
          "777-content-id-of-employing-eu-citizens" => "Employing EU citizens",
          "000-content-id-of-food-drink-tobacco-facet" => "Special category",
        )
      }

      it {
        is_expected.to eql "EU Exit guidance for your business in the following categories: 'Special category', 'Ports and airports', 'Employing EU citizens', 'EU funding'"
      }
    end
  end
end
