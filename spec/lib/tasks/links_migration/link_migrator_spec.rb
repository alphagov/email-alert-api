require "rails_helper"
require "tasks/links_migration/link_migrator"

RSpec.describe Tasks::LinksMigration::LinkMigrator do
  class FakeContentStore
    require "rspec/mocks/standalone"

    def mock_content_item1
      double("content_item1", content_id: "uuid-888")
    end

    def mock_content_item2
      double("content_item2", content_id: nil)
    end

    def content_item(path)
      case path
      when "/topic/oil-and-gas/something"
        mock_content_item1
      when "benefits/some-other-thing"
        mock_content_item2
      else
        nil
      end
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

  describe "#populate_topic_links", focus: true do
    it "copies content IDs for appropriate topic tag matches" do
      subscriber_list = create(:subscriber_list, tags: {topics: ["oil-and-gas/something"]})

      Tasks::LinksMigration::LinkMigrator.new.populate_topic_links
      subscriber_list.reload

      expect(subscriber_list.links).to eq(topics: ["uuid-888"])
    end

    it "raises an exception if the content item has no ID" do
      create(:subscriber_list, tags: {topics: ["benefits/some-other-thing"]})

      expect {Tasks::LinksMigration::LinkMigrator.new.populate_topic_links}.to raise_error(
        Tasks::LinksMigration::LinkMigrator::DodgyBasePathError
      )
    end

    it "raises an exception if no content item is returned" do
      create(:subscriber_list, tags: {topics: ["foobars"]})

      expect {Tasks::LinksMigration::LinkMigrator.new.populate_topic_links}.to raise_error(
        Tasks::LinksMigration::LinkMigrator::DodgyBasePathError
      )
    end
  end
end
