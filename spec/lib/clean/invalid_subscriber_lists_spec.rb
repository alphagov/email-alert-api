require "gds_api/test_helpers/content_store"
require "gds_api/test_helpers/worldwide"

RSpec.describe Clean::InvalidSubscriberLists do
  include ::GdsApi::TestHelpers::Worldwide
  include ::GdsApi::TestHelpers::ContentStore

  let(:subject) { described_class.new }

  context "when there are invalid lists" do
    let!(:list) { create(:subscriber_list_with_invalid_tags, :skip_validation) }

    describe "#lists" do
      it "returns all subscriber_lists that are invalid" do
        expect(subject.lists.count).to eq(1)
        expect(subject.lists).to include(list)
      end
    end
  end

  context "when there are no invalid lists" do
    let!(:list) { create(:subscriber_list) }

    describe "#lists" do
      it "returns zero subscriber lists" do
        expect(subject.lists.count).to eq(0)
        expect(subject.lists).to_not include(list)
      end
    end
  end

  describe "#valid_list" do
    let(:tags) {
      {
        organisations: { any: %w[ministry-of-silly-walks ministry-of-sillier-walks] },
        people: { all: %w[harry-potter] },
        world_locations: { all: %w[france iceland malta], any: %w[australia] },
        content_store_document_type: { any: %w[news_and_communications] },
        part_of_taxonomy_tree: { any: %w[taxon], all: %w[another-taxon] },
      }
    }
    let!(:valid_list) { create(:subscriber_list) }
    let!(:invalid_list) { create(:subscriber_list_with_invalid_tags, :skip_validation, tags: tags) }

    it "returns nil when given a valid list" do
      expect(subject.valid_list(valid_list)).to be nil
    end

    context "when given an invalid list" do
      before :each do
        content_store_has_organisations
        content_store_has_people
        stub_worldwide_api_has_selection_of_locations
      end

      context "during a dry run" do
        it "wont create a new list" do
          expect { subject.valid_list(invalid_list) }.not_to(change { SubscriberList.count })
        end
      end

      it "returns a new valid list" do
        expect(SubscriberList.count).to eq(2)
        new_list = subject.valid_list(invalid_list, dry_run: false)
        expect(SubscriberList.count).to eq(3)
        expect(new_list).to be_instance_of(SubscriberList)
        expect(new_list.invalid?).to be false
        expect(new_list.tags).to eq({})
        expect(new_list.links).to eq(
          organisations: { any: %w[silly-walks-id sillier-walks-walks-id] },
          people: { all: %w[harry-potter-id] },
          world_locations: {
            all: %w[content_id_for_france content_id_for_iceland content_id_for_malta],
            any: %w[content_id_for_australia],
          },
          content_store_document_type: { any: %w[news_and_communications] },
          taxon_tree: { any: %w[taxon], all: %w[another-taxon] },
        )
      end
    end

    context "when given a list with invalid value" do
      let(:tags) {
        {
          people: { all: %w[harry-potter non-existant-person] },
        }
      }

      before :each do
        content_store_has_people
      end

      it "wont create a new list" do
        expect {
          subject.valid_list(invalid_list)
        }.not_to(change { SubscriberList.count })
      end
    end
  end

  describe "#copy_subscribers" do
    let!(:from_list) { create(:subscriber_list_with_subscribers) }
    let!(:to_list) { create(:subscriber_list) }
    let!(:subscriber) { create(:subscriber) }
    let!(:subscription1) { create(:subscription, subscriber: subscriber, subscriber_list: from_list) }
    let!(:subscription2) { create(:subscription, subscriber: subscriber, subscriber_list: to_list) }

    it "creates new subscriptions to the to_list for the subscribers to the for_list" do
      expect {
        subject.copy_subscribers(from_list, to_list, dry_run: false)
      }.to(change { to_list.subscribers.count }.by(5))
    end

    it "does not change the subscriptions to the from_list" do
      expect {
        subject.copy_subscribers(from_list, to_list, dry_run: false)
      }.not_to(change { from_list.subscribers.count })
    end

    context "when it is a dry run, which is the default" do
      it "does not create any new subscriptions" do
        expect {
          subject.copy_subscribers(from_list, to_list)
        }.not_to(change { to_list.subscribers.count })
        expect {
          subject.copy_subscribers(from_list, to_list)
        }.not_to(change { from_list.subscribers.count })
      end
    end

    context "when not given subscriber lists" do
      it "does nothing" do
        expect {
          subject.copy_subscribers(nil, nil)
        }.not_to(change { Subscription.count })
      end
    end
  end

  describe "deactivate_invalid_subscriptions" do
    let!(:invalid_list1) { create(:subscriber_list_with_invalid_tags, :skip_validation) }
    let!(:invalid_list2) { create(:subscriber_list_with_invalid_tags, :skip_validation) }
    let!(:valid_list) { create(:subscriber_list) }
    let!(:subscriber) { create(:subscriber) }
    let!(:subscription1) { create(:subscription, subscriber: subscriber, subscriber_list: invalid_list1) }
    let!(:subscription2) { create(:subscription, subscriber: subscriber, subscriber_list: invalid_list2) }
    let!(:subscription3) { create(:subscription, subscriber: subscriber, subscriber_list: valid_list) }

    it "deactivates a subscribers subscriptions to invalid lists" do
      expect {
        subject.deactivate_invalid_subscriptions(dry_run: false)
      }.to(change {
        subscriber.subscriptions.active.count
      }.by(-2))
    end

    it "deactivates invalid subscriptions" do
      expect(subscription1.ended?).to be false
      expect(subscription2.ended?).to be false
      subject.deactivate_invalid_subscriptions(dry_run: false)
      expect(subscription1.reload.ended?).to be true
      expect(subscription2.reload.ended?).to be true
    end

    it "does nothing during a dry run, which is the default" do
      expect {
        subject.deactivate_invalid_subscriptions
      }.not_to(change {
        subscriber.subscriptions.active.count
      })
    end
  end

  describe "#destroy_invalid_subscriber_lists" do
    let!(:invalid_list1) { create(:subscriber_list_with_invalid_tags, :skip_validation, subscriber_count: 0) }
    let!(:invalid_list2) { create(:subscriber_list_with_invalid_tags, :skip_validation) }
    let!(:valid_list) { create(:subscriber_list) }
    let!(:subscriber) { create(:subscriber) }
    let!(:subscription) { create(:subscription, :ended, subscriber: subscriber, subscriber_list: invalid_list1) }

    it "deletes invalid subscriber lists which don't have active subscriptions" do
      expect {
        subject.destroy_invalid_subscriber_lists(dry_run: false)
      }.to(change {
        SubscriberList.count
      }.by(-1))
    end

    it "deletes subscriptions to invalid subscriber lists" do
      expect {
        subject.destroy_invalid_subscriber_lists(dry_run: false)
      }.to(change { subscriber.subscriptions.count }.by(-1))
    end

    it "does nothing during a dry run, which is the default" do
      expect {
        subject.destroy_invalid_subscriber_lists
      }.not_to(change { SubscriberList.count })
    end
  end

  def content_store_has_organisations
    content_store_has_item(
      "/government/organisations/ministry-of-silly-walks",
      {
        "base_path" => "/government/organisations/ministry-of-silly-walks",
        "content_id" => "silly-walks-id",
      }.to_json,
    )

    content_store_has_item(
      "/government/organisations/ministry-of-sillier-walks",
      {
        "base_path" => "/government/organisations/ministry-of-sillier-walks",
        "content_id" => "sillier-walks-walks-id",
      }.to_json,
    )
  end

  def content_store_has_people
    content_store_has_item(
      "/government/people/harry-potter",
      {
        "base_path" => "/government/people/harry-potter",
        "content_id" => "harry-potter-id",
      }.to_json,
    )
    stub_content_store_does_not_have_item(
      "/government/people/non-existant-person",
    )
  end
end
