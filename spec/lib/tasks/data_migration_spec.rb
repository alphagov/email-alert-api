require "gds_api/test_helpers/content_store"

RSpec.describe "data_migration" do
  include GdsApi::TestHelpers::ContentStore

  describe "update_subscriber_list_tag" do
    before do
      Rake::Task["data_migration:update_subscriber_list_tag"].reenable
    end

    it "renames a country in a 'destination_country' tag" do
      list = create :subscriber_list, tags: { location: { any: %w[old other] } }

      expect {
        Rake::Task["data_migration:update_subscriber_list_tag"].invoke("location", "old", "new")
      }.to output.to_stdout

      expect(list.reload.tags[:location][:any]).to match_array %w[new other]
    end

    it "does not update a list without a matching tag" do
      list = create :subscriber_list, tags: { location: { any: %w[other] } }
      Rake::Task["data_migration:update_subscriber_list_tag"].invoke("location", "old", "new")
      expect(list.reload.tags[:location][:any]).to match_array %w[other]
    end
  end

  describe "update_subscriber_list_slug" do
    before do
      Rake::Task["data_migration:update_subscriber_list_slug"].reenable
    end

    it "updates the slug of the list" do
      list = create :subscriber_list

      expect {
        Rake::Task["data_migration:update_subscriber_list_slug"].invoke(list.slug, "new-slug")
      }.to output.to_stdout
    end
  end

  describe "fetch_subscriber_list_descriptions" do
    before do
      Rake::Task["data_migration:fetch_subscriber_list_descriptions"].reenable
      stub_content_store_has_item("/an/example/page")
    end

    it "updates the subscriber list description" do
      list = create(:subscriber_list, :for_single_page_subscription)

      Rake::Task["data_migration:fetch_subscriber_list_descriptions"].invoke
      expect(list.reload.description).to eq("Description for /an/example/page")
    end
  end
end
