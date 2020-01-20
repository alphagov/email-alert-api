RSpec.describe Clean::MigrateSpecialistSubscriberLists do
  context "when there are affected lists" do
    subject(:cleaner) { described_class.new }

    let(:created_at) { Date.new(2019, 12, 20) }
    let!(:a_list_bad) { create(:subscriber_list_with_subscribers, slug: a_list_bad_slug, tags: a_list_tags_bad, created_at: created_at) }
    let!(:a_list_good) { create(:subscriber_list_with_subscribers, slug: a_list_good_slug, tags: a_list_tags_good, created_at: created_at) }
    let!(:b_list_bad) { create(:subscriber_list_with_subscribers, slug: b_list_bad_slug, tags: b_list_tags_bad, created_at: created_at) }

    let(:a_list_bad_slug) { "a_list_bad_slug" }
    let(:a_list_good_slug) { "a_list_good_slug" }
    let(:b_list_bad_slug) { "b_list_bad_slug" }

    let(:a_list_tags_bad) { { "vessel_type" => { "any" => %w[recreational-craft-power] }, "document_type" => { "any" => %w[maib_report] }, "format" => { "any" => %w[maib_report] } } }
    let(:a_list_tags_good) { { "vessel_type" => { "any" => %w[recreational-craft-power] }, "format" => { "any" => %w[maib_report] } } }
    let(:b_list_tags_bad) { { "case_type" => { "any" => %w[markets mergers consumer-enforcement regulatory-references-and-appeals review-of-orders-and-undertakings] }, "document_type" => { "any" => %w[cma_case] }, "format" => { "any" => %w[cma_case] } } }
    let(:b_list_tags_good) { { "case_type" => { "any" => %w[markets mergers consumer-enforcement regulatory-references-and-appeals review-of-orders-and-undertakings] }, "format" => { "any" => %w[cma_case] } } }

    describe "#lists" do
      it "returns only the invalid subscriber lists" do
        expect(cleaner.lists.count).to eq(2)
        expect(cleaner.lists).to eq([a_list_bad, b_list_bad])
      end
    end

    describe "#migrate_subscribers_to_working_lists" do
      subject(:migration) { cleaner.migrate_subscribers_to_working_lists(dry_run: dry_run) }
      let(:dry_run) { false }

      context "during a dry run" do
        let(:dry_run) { true }
        it "wont migrate subscribers" do
          expect { subject }.not_to(change { a_list_good.subscriptions.active.count })
          expect { subject }.not_to(change { SubscriberList.count })
        end
      end

      it "migrates all affected subscribers to new working lists" do
        expect { subject }.to(change { a_list_good.subscriptions.active.count }.by(5))
      end

      it "deactivates existing subscriptions" do
        expect { subject }.to(change { a_list_bad.subscriptions.active.count }.by(-5))
      end

      it "creates a new subscriber list when necessary" do
        expect(b_list_bad.subscriptions.active.count).to eq(5)
        migration
        expect(SubscriberList.last.tags).to eq(b_list_tags_good.deep_symbolize_keys)
        expect(SubscriberList.last.slug).to include(b_list_bad_slug)
        expect(b_list_bad.subscriptions.active.count).to eq(0)
        expect(SubscriberList.last.subscriptions.active.count).to eq(5)
      end
    end
  end
end
