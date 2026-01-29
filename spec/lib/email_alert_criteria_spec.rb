require "gds_api/test_helpers/content_item_helpers"

RSpec.describe EmailAlertCriteria do
  include GdsApi::TestHelpers::ContentItemHelpers
  subject { described_class.new(content_item:) }

  describe "#would_trigger_alert?" do
    context "when the content item has no title" do
      let!(:content_item) { valid_content_item.except("title") }

      it "should return false" do
        expect(subject.would_trigger_alert?).to be false
      end
    end

    context "when the content item has no base_path" do
      let!(:content_item) { valid_content_item.except("base_path") }

      it "should return false" do
        expect(subject.would_trigger_alert?).to be false
      end
    end

    context "when the content item has no public_updated_at" do
      let!(:content_item) { valid_content_item.except("public_updated_at") }

      it "should return false" do
        expect(subject.would_trigger_alert?).to be false
      end
    end

    context "when the content item is not english" do
      let!(:content_item) { valid_content_item.merge("locale" => "cy") }

      it "should return false" do
        expect(subject.would_trigger_alert?).to be false
      end
    end

    context "when the content item does not have a change note" do
      let!(:content_item) do
        ci = valid_content_item
        ci["details"].delete("change_history")
        ci
      end

      it "should return false" do
        expect(subject.would_trigger_alert?).to be false
      end
    end

    context "when the content item is from a blocked app" do
      let!(:content_item) { valid_content_item.merge("publishing_app" => "collections-publisher") }

      it "should return false" do
        expect(subject.would_trigger_alert?).to be false
      end
    end

    context "when the content item is from a blocked document_type" do
      let!(:content_item) { valid_content_item.merge("document_type" => "coming_soon") }

      it "should return false" do
        expect(subject.would_trigger_alert?).to be false
      end
    end

    context "when the content item is otherwise valid but doesn't have a parent/tag/supertype" do
      let!(:content_item) { valid_content_item_no_parent }

      it "should return true" do
        expect(subject.would_trigger_alert?).to be false
      end
    end

    context "when the content item is valid because it is the single instance of service_manual_service_standard" do
      let!(:content_item) { valid_content_item_no_parent.merge("links" => { "parent" => [{ "content_id" => "00f693d4-866a-4fe6-a8d6-09cd7db8980b" }] }) }

      it "should return true" do
        expect(subject.would_trigger_alert?).to be true
      end
    end

    context "when the content item is valid because it contains a supported link type" do
      let!(:content_item) { valid_content_item_no_parent.merge("links" => { "taxons" => [{ "locale" => "en" }] }) }

      it "should return true" do
        expect(subject.would_trigger_alert?).to be true
      end
    end

    context "when the content item does not have a relevant supertype" do
      let!(:content_item) { valid_content_item_no_parent.merge("government_document_supertype" => "other") }

      it "should return false" do
        expect(subject.would_trigger_alert?).to be false
      end
    end

    context "when the content item is valid because it has a relevant government_document_supertype" do
      let!(:content_item) { valid_content_item_no_parent.merge("government_document_supertype" => "news") }

      it "should return true" do
        expect(subject.would_trigger_alert?).to be true
      end
    end

    context "when the content item is valid because it has a relevant email_document_supertype" do
      let!(:content_item) { valid_content_item_no_parent.merge("email_document_supertype" => "news") }

      it "should return true" do
        expect(subject.would_trigger_alert?).to be true
      end
    end
  end
end

def valid_content_item
  content_item = content_item_for_base_path("/criteria-test")
  content_item["base_path"] = "/criteria-test"
  content_item["locale"] = "en"
  content_item["details"].merge!("change_history" => [{
    "note" => "updated!",
    "public_timestamp" => content_item["public_updated_at"],
  }])
  content_item["publishing_app"] = "whitehall"
  content_item["document_type"] = "news"
  content_item["parent"] = %w[00f693d4-866a-4fe6-a8d6-09cd7db8980b]
  content_item
end

def valid_content_item_no_parent
  content_item = valid_content_item
  content_item.delete("parent")
  content_item
end
