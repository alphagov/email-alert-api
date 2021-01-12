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

  describe "temp_unsubscribe_old_brexit_lists" do
    before do
      Rake::Task["data_migration:temp_unsubscribe_old_brexit_lists"].reenable
    end

    it "bulk unsubscribes across a couple of lists" do
      list1 = create(:subscriber_list, id: 18_200)
      list2 = create(:subscriber_list, id: 23_131)

      create(:subscription, subscriber_list: list1)
      create(:subscription, subscriber_list: list2)
      create(:subscription)

      Rake::Task["data_migration:temp_unsubscribe_old_brexit_lists"].invoke
      expect(Subscription.active.count).to eq(1)
    end
  end
end
