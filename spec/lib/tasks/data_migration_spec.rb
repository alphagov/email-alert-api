RSpec.describe "data_migration" do
  describe "move_all_subscribers" do
    let(:old_list) { create(:subscriber_list) }
    let(:new_list) { create(:subscriber_list) }
    let(:subscriber_instance) { double("SubscriberListMover") }

    before do
      Rake::Task["data_migration:move_all_subscribers"].reenable

      ENV["BULK_MIGRATE_CONFIRMATION_EMAIL_ACCOUNT"] = "test@test.com"

      old_list.subscriptions << create_list(:subscription, 2)
      allow(SubscriberListMover).to receive(:new).and_return(subscriber_instance)
    end

    it "includes argument to send email if env var is set" do
      ENV["SEND_EMAIL"] = "true"

      expect(subscriber_instance).to receive(:call)
      expect(SubscriberListMover).to receive(:new).with(from_slug: old_list.slug, to_slug: new_list.slug, send_email: "true")

      Rake::Task["data_migration:move_all_subscribers"].invoke(old_list.slug, new_list.slug)
    end

    it "does not include argument to send email if env var is not set" do
      ENV["SEND_EMAIL"] = nil

      expect(subscriber_instance).to receive(:call)
      expect(SubscriberListMover).to receive(:new).with(from_slug: old_list.slug, to_slug: new_list.slug)

      Rake::Task["data_migration:move_all_subscribers"].invoke(old_list.slug, new_list.slug)
    end
  end

  describe "rename_alert_subscription_lists" do
    let(:new_list) { create(:subscriber_list) }

    before do
      Rake::Task["data_migration:rename_alert_subscription_lists"].reenable

      ENV["BULK_MIGRATE_CONFIRMATION_EMAIL_ACCOUNT"] = "test@test.com"
    end

    it "does not move or update any subscribers if the slug isn't an alert type" do
      list = create :subscriber_list
      list.tags = { alert_type: { any: %w[bananas pears] } }
      list.save!

      expect { Rake::Task["data_migration:rename_alert_subscription_lists"].invoke("apples", "oranges") }.not_to(change { SubscriberList })
    end

    it "does not move or update any subscribers if the subscriber list does not have any active subscribers" do
      list = create :subscriber_list
      list.tags = { alert_type: { any: %w[old other] } }
      list.save!

      expect { Rake::Task["data_migration:rename_alert_subscription_lists"].invoke("old", "new") }.not_to(change { SubscriberList })
    end

    it "moves subscribers to new list if they have alert type" do
      subscription1 = create :subscription
      list1 = subscription1.subscriber_list
      list1.tags = { alert_type: { any: %w[old other] } }
      list1.save!

      subscription2 = create :subscription
      list2 = subscription2.subscriber_list
      list2.tags = { alert_type: { any: %w[old other] } }
      list2.save!

      expect(list1.subscribers.count).to eq(1)

      expect {
        Rake::Task["data_migration:rename_alert_subscription_lists"].invoke("old", "new")
      }.to output(/Moving #{list2.slug} subscribers to #{list1.slug}/).to_stdout

      expect(list1.subscribers.count).to eq(2)
    end

    it "updates the list with new alert type" do
      subscription = create :subscription
      list = subscription.subscriber_list
      list.tags = { alert_type: { any: %w[old other] } }
      list.save!

      expect {
        Rake::Task["data_migration:rename_alert_subscription_lists"].invoke("old", "new")
      }.to output("Updating #{list.slug} with tags [\"other\", \"new\"] (was: [\"old\", \"other\"])\n").to_stdout

      expect(Subscriber.first.subscriber_lists.first.tags[:alert_type][:any]).to eq(%w[other new])
    end
  end

  describe "find_subscriber_list_by_title" do
    before do
      Rake::Task["data_migration:find_subscriber_list_by_title"].reenable
    end

    it "outputs a list of subscriber lists that contain the title" do
      list1 = create(:subscriber_list, title: "Special title")
      list2 = create(:subscriber_list, title: "Special title")

      expect { Rake::Task["data_migration:find_subscriber_list_by_title"].invoke("Special title") }
        .to output(
          <<~TEXT,
            Found 2 subscriber lists containing 'Special title'
            =============================
            title: Special title
            slug: #{list1.slug}
            =============================
            title: Special title
            slug: #{list2.slug}
          TEXT
        ).to_stdout
    end

    it "raises an error if title isn't found in any subscriber lists" do
      # create(:subscriber_list)

      expect {
        Rake::Task["data_migration:find_subscriber_list_by_title"].invoke("Unknown title")
      }.to raise_error(RuntimeError, /Cannot find any subscriber lists with title containing `Unknown title`/)
    end
  end

  describe "update_subscriber_list_tag" do
    before do
      Rake::Task["data_migration:update_subscriber_list_tag"].reenable
    end

    it "renames a country in a 'destination_country' tag" do
      list = create :subscriber_list, tags: { location: { any: %w[old other] } }

      expect {
        Rake::Task["data_migration:update_subscriber_list_tag"].invoke("location", "old", "new")
      }.to output("Updated location in #{list.title} to [\"other\", \"new\"]\n").to_stdout

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

    it "updates the slug of the list if subscriber list exists" do
      list = create :subscriber_list

      expect {
        Rake::Task["data_migration:update_subscriber_list_slug"].invoke(list.slug, "new-slug")
      }.to output(/Subscriber list updated with slug: new-slug/).to_stdout
    end

    it "raises an error if subscriber list does not exist" do
      expect {
        Rake::Task["data_migration:update_subscriber_list_slug"].invoke("old-slug", "new-slug")
      }.to raise_error(RuntimeError, /Cannot find subscriber list with old-slug/)
    end
  end
end
