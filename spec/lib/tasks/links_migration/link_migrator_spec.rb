require "rails_helper"
require "tasks/links_migration/link_migrator"

RSpec.describe Tasks::LinksMigration::LinkMigrator do
  class FakeContentStore
    require "rspec/mocks/standalone"

    def mock_content_item
      double("content_item", content_id: "uuid-888")
    end

    def content_item(path)
      path == "/topic/oil-and-gas/something" ? mock_content_item : nil
    end
  end

  before do
    allow(Services).to receive(:content_store).and_return(FakeContentStore.new)
  end

  around do |example|
    the_real_stdout = $stdout
    $stdout = StringIO.new
    example.run
    $stdout = the_real_stdout
  end

  describe "#populate_topic_links" do
    it "copies content IDs for appropriate topic tag matches" do
      subscriber_list1 = create(:subscriber_list, tags: {topics: ["oil-and-gas/something"]})
      subscriber_list2 = create(:subscriber_list, tags: {topics: ["benefits/some-other-thing"]})
      subscriber_list3 = create(:subscriber_list, tags: {policies: ["foobars"]})

      Tasks::LinksMigration::LinkMigrator.new.populate_topic_links
      [subscriber_list1, subscriber_list2, subscriber_list3].each { |s| s.reload }

      expect(subscriber_list1.links).to eq(topics: ["uuid-888"])
      expect(subscriber_list2.links).to eq({})
      expect(subscriber_list3.links).to eq({})
    end
  end

  describe "#destroy_non_matching_subscriber_lists" do
    it "destroys subscriber lists with no match in the content store" do
      subscriber_list = create(:subscriber_list, tags: {topics: ["oil-and-gas/something"]})
      create(:subscriber_list, tags: {topics: ["benefits/some-other-thing"]})

      Tasks::LinksMigration::LinkMigrator.new.destroy_non_matching_subscriber_lists

      expect(SubscriberList.count).to eq 1
      expect(SubscriberList.first).to eq subscriber_list
    end
  end
end
