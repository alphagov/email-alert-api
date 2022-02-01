RSpec.describe "data_migration" do
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
end
