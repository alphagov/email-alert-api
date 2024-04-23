require "gds_api/test_helpers/content_store"

RSpec.describe "report" do
  include ContentItemHelpers
  include GdsApi::TestHelpers::ContentStore

  describe "matched_content_changes" do
    it "outputs a CSV of matched content changes" do
      expect { Rake::Task["report:matched_content_changes"].invoke }
        .to output.to_stdout
    end
  end

  describe "csv_subscriber_lists" do
    it "outputs a report of data concerning subscriber lists for a given date" do
      expect { Rake::Task["report:csv_subscriber_lists"].invoke(6.months.ago.to_s) }
        .to output.to_stdout
    end
  end

  describe "potentially_dead_lists" do
    it "outputs a report of data for subscriber lists that appear to be inactive" do
      expect { Rake::Task["report:potentially_dead_lists"].invoke }
        .to output.to_stdout
    end
  end

  describe "subscriber_list_subscriber_count" do
    it "outputs a count of subscribers for subscriber lists" do
      expect { Rake::Task["report:subscriber_list_subscriber_count"].invoke("/url") }
        .to output.to_stdout
    end
  end

  describe "single_page_notifications_top_subscriber_lists" do
    it "outputs a report of single page notification subscriber lists" do
      expect { Rake::Task["report:single_page_notifications_top_subscriber_lists"].invoke }
        .to output.to_stdout
    end
  end

  describe "historical_content_change_statistics" do
    it "outputs a report of people notified for recent content change" do
      expect { Rake::Task["report:historical_content_change_statistics"].invoke("/url") }
        .to output.to_stdout
    end
  end

  describe "future_content_change_statistics" do
    context "with a valid content item" do
      before do
        subscriber_list = create(:subscriber_list, :for_single_page_subscription)
        # match_by_tags_content_item_for_subscriber_list(subscriber_list:)
        @path = subscriber_list_path(subscriber_list)
      end

      it "outputs a report of people who would be notified of a major change" do
        expect { Rake::Task["report:future_content_change_statistics"].invoke(@path) }
          .to output(/title 1 \([0-9]+ active subscribers\)/).to_stdout
      end
    end

    context "with a content item that wouldn't trigger an alert" do
      before do
        subscriber_list = create(:subscriber_list, :for_single_page_subscription)
        match_by_tags_non_triggering_content_item_for_subscriber_list(subscriber_list:)
        @path_2 = subscriber_list_path(subscriber_list)
      end

      it "outputs a report of people who would be notified of a major change" do
        expect { Rake::Task["report:future_content_change_statistics"].invoke(@path_2) }
          .to output(/would not trigger an email alert/).to_stdout
      end
    end
  end

  describe "finder_statistics" do
    before do
      content_item = content_item_for_base_path("/url")
      stub_content_store_has_item("/url", content_item)
    end

    it "outputs a report of people who are subscribed to lists created from a finder" do
      expect { Rake::Task["report:finder_statistics"].invoke("/url") }
        .to output.to_stdout
    end
  end
end
