require "gds_api/test_helpers/content_store"

RSpec.describe SubscriberListAuditWorker do
  include GdsApi::TestHelpers::ContentStore

  let(:required_match_attributes) do
    {
      "locale" => "en",
      "government_document_supertype" => "email",
      "details" => {
        "tags" => {
          "tribunal_decision_categories" => %w[agency-workers],
        },
        "change_history" => [
          { "public_timestamp" => Time.zone.now.to_s, "note" => "changed" },
        ],
      },
    }
  end

  before do
    @sl1 = create(:subscriber_list, :for_single_page_subscription)
    @sl2 = create(:subscriber_list, :for_single_page_subscription, tags: { tribunal_decision_categories: { any: %w[part-time-workers] } })
    @sl3 = create(:subscriber_list, :for_single_page_subscription, tags: { tribunal_decision_categories: { any: %w[flexible-working] } })

    @path_sl1 = URI(@sl1.url).path
    @path_sl2 = URI(@sl2.url).path
    @path_sl3 = URI(@sl3.url).path

    # First content item matchs first subscriber list
    content_item = content_item_for_base_path(@path_sl1).merge(required_match_attributes)
    stub_content_store_has_item(@path_sl1, content_item)

    # Second content item matchs second subscriber list
    content_item = content_item_for_base_path(@path_sl2).merge(required_match_attributes).merge(
      "details" => {
        "tags" => {
          "tribunal_decision_categories" => %w[part-time-workers],
        },
        "change_history" => [
          { "public_timestamp" => Time.zone.now.to_s, "note" => "changed" },
        ],
      },
    )
    stub_content_store_has_item(@path_sl2, content_item)

    # Third content item matchs third subscriber list but doesn't have a change history, so
    # can't trigger email alerts.
    content_item = content_item_for_base_path(@path_sl3).merge(required_match_attributes).merge(
      "details" => {
        "tags" => {
          "tribunal_decision_categories" => %w[part-time-workers],
        },
      },
    )
    stub_content_store_has_item(@path_sl3, content_item)
  end

  describe "#perform" do
    let(:url_batch) { [@sl1.url, @sl2.url, @sl3.url] }
    let(:audit_start_time) { Time.zone.now - 5.minutes }

    it "Updates subscriber lists that can be triggered" do
      described_class.new.perform(url_batch, audit_start_time.to_s)

      expect(SubscriberList.where(last_audited_at: Time.zone.parse(audit_start_time.to_s)).count).to eq(2)
    end

    it "Doesn't update subscriber lists that can't be triggered" do
      described_class.new.perform(url_batch, audit_start_time.to_s)

      @sl3.reload
      expect(@sl3.last_audited_at).to be_nil
    end

    context "when a content item in the sitemap doesn't exist in the content store" do
      before do
        stub_content_store_does_not_have_item(@path_sl1)
      end

      it "ignores that item and continues" do
        described_class.new.perform(url_batch, audit_start_time.to_s)

        expect(SubscriberList.where(last_audited_at: nil).count).to eq(2)
      end
    end

    context "when everything has been audited recently" do
      before do
        @sl1.update_column(:last_audited_at, Time.zone.now)
        @sl2.update_column(:last_audited_at, Time.zone.now)
        @sl3.update_column(:last_audited_at, Time.zone.now)
      end

      it "shortcuts to completion" do
        expect(EmailAlertCriteria).not_to receive(:new)

        described_class.new.perform(url_batch, audit_start_time.to_s)
      end
    end
  end
end
