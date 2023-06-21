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

  describe "migrate_users_from_bad_lists" do
    before do
      Rake::Task["data_migration:migrate_users_from_bad_lists"].reenable
    end

    it "fetches taxonomy topic subscriber lists and migrates users from bad lists to good lists" do
      bad_list = create(:subscriber_list,
                        url: "/health-and-social-care/dementia",
                        title: "Dementia",
                        slug: "dementia",
                        links: {},
                        content_id: "cc9eb8ab-7701-43a7-a66d-bdc5046224c0")
      good_list = create(:subscriber_list,
                         url: "/health-and-social-care/dementia",
                         title: "Dementia",
                         slug: "dementia-2",
                         links: { "taxon_tree" => { "any" => %w[a0774926-fa64-4ecf-84aa-1341b638933a] } },
                         content_id: nil)

      create(:subscription, subscriber_list: good_list)
      create(:subscription, subscriber_list: bad_list)

      message = <<~HEREDOC
        Bad subscriptions count for taxonony emails: #{bad_list.active_subscriptions_count}
        Running migration...
        #{bad_list.active_subscriptions_count} active subscribers moving from #{bad_list.slug} to #{good_list.slug}
        1 active subscribers moved from #{bad_list.slug} to #{good_list.slug}.
        Migration complete
        There are 0 remaining bad subscriptions for taxonomy lists.
      HEREDOC

      expect(bad_list.active_subscriptions_count).to be 1
      expect(good_list.active_subscriptions_count).to be 1

      expect { Rake::Task["data_migration:migrate_users_from_bad_lists"].invoke }.to output(message).to_stdout

      expect(bad_list.active_subscriptions_count).to be 0
      expect(good_list.active_subscriptions_count).to be 2
    end
  end
end
