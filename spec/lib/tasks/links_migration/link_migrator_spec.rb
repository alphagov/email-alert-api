require "rails_helper"
require "tasks/links_migration/topic_link_migrator"
require "tasks/links_migration/policy_link_migrator"

RSpec.describe "Links Migration" do
  class FakeContentStore
    require "rspec/mocks/standalone"

    def mock_content_item1
      double("content_item1", content_id: "uuid-888")
    end

    def mock_content_item2
      double("content_item2", content_id: "uuid-999")
    end

    def mock_content_item_no_content_id
      double("content_item_no_content_id", content_id: nil)
    end

    def content_item(path)
      case path
      when "/topic/oil-and-gas/something"
        mock_content_item1
      when "/government/policies/tax-credits"
        mock_content_item2
      when "topic/benefits/some-other-thing"
        mock_content_item_no_content_id
      when "goverment/policies/some-other-thing"
        mock_content_item_no_content_id
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

  describe Tasks::LinksMigration::TopicLinkMigrator do
    describe "#populate_links" do
      let(:subject) { Tasks::LinksMigration::TopicLinkMigrator.new }

      it "copies content IDs for appropriate topic tag matches" do
        subscriber_list = create(:subscriber_list, tags: {topics: ["oil-and-gas/something"]})

        subject.populate_links
        subscriber_list.reload

        expect(subscriber_list.links).to eq(topics: ["uuid-888"])
      end

      it "raises an exception if the content item has no ID" do
        create(:subscriber_list, tags: {topics: ["benefits/some-other-thing"]})

        expect {subject.populate_links}.to raise_error(
          Tasks::LinksMigration::TopicLinkMigrator::DodgyBasePathError
        )
      end

      it "raises an exception if no content item is returned" do
        create(:subscriber_list, tags: {topics: ["no-match"]})

        expect {subject.populate_links}.to raise_error(
          Tasks::LinksMigration::TopicLinkMigrator::DodgyBasePathError
        )
      end
    end
  end

  describe Tasks::LinksMigration::PolicyLinkMigrator do
    let(:subject) { Tasks::LinksMigration::PolicyLinkMigrator.new }

    describe "#populate_policy_links" do
      it "copies content IDs for appropriate policy tag matches" do
        subscriber_list = create(:subscriber_list, tags: {policy: ["tax-credits"]})

        subject.populate_policy_links
        subscriber_list.reload

        expect(subscriber_list.links).to eq(policies: ["uuid-999"])
      end

      it "raises an exception if the content item has no ID" do
        create(:subscriber_list, tags: {policy: ["some-other-thing"]})

        expect {subject.populate_policy_links}.to raise_error(
          Tasks::LinksMigration::PolicyLinkMigrator::DodgyBasePathError
        )
      end

      it "raises an exception if no content item is returned" do
        create(:subscriber_list, tags: {policy: ["no-match"]})

        expect {subject.populate_policy_links}.to raise_error(
          Tasks::LinksMigration::PolicyLinkMigrator::DodgyBasePathError
        )
      end
    end
  end
end
