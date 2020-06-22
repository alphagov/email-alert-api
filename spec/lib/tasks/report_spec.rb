RSpec.describe "report" do
  describe "matched_content_changes" do
    it "outputs a CSV of matched content changes" do
      expect { Rake::Task["report:matched_content_changes"].invoke }
        .to output.to_stdout
    end
  end

  describe "content_change_email_status_count" do
    it "outputs a report of content change email statuses" do
      content_change = create :content_change

      expect { Rake::Task["report:content_change_email_status_count"].invoke(content_change.id.to_s) }
        .to output.to_stdout
    end
  end

  describe "content_change_failed_emails" do
    it "outputs a report of failed content change emails" do
      content_change = create :content_change

      expect { Rake::Task["report:content_change_failed_emails"].invoke(content_change.id.to_s) }
        .to output.to_stdout
    end
  end

  describe "count_subscribers_report" do
    it "outputs a report of subscribers for a list" do
      subscriber_list = create :subscriber_list

      expect { Rake::Task["report:count_subscribers"].invoke(subscriber_list.slug) }
        .to output.to_stdout
    end
  end

  describe "count_subscribers_on_report" do
    it "outputs a report of subscribers for a list on a date" do
      subscriber_list = create :subscriber_list

      expect { Rake::Task["report:count_subscribers_on"].invoke("2019-08-01", subscriber_list.slug) }
        .to output.to_stdout
    end
  end

  describe "find_delivery_attempts" do
    it "outputs a report of delivery attempts over a date range" do
      create :delivered_delivery_attempt, created_at: "2019-08-03"

      expect { Rake::Task["report:find_delivery_attempts"].invoke("2019-08-01", "2019-08-07") }
        .to output.to_stdout
    end
  end

  describe "csv_from_ids" do
    it "outputs a report of subscriptions to specified lists" do
      expect { Rake::Task["report:csv_from_ids"].invoke("1") }
        .to output.to_stdout
    end
  end

  describe "csv_from_ids_at" do
    it "outputs a report of subscriptions to specified lists on a date" do
      expect { Rake::Task["report:csv_from_ids_at"].invoke("2018-08-08", "1") }
        .to output.to_stdout
    end
  end

  describe "csv_from_slugs" do
    it "outputs a report of subscriptions to specified lists" do
      expect { Rake::Task["report:csv_from_slugs"].invoke("a-slug") }
        .to output.to_stdout
    end
  end

  describe "csv_from_slugs_at" do
    it "outputs a report of subscriptions to specified lists on a date" do
      expect { Rake::Task["report:csv_from_slugs_at"].invoke("2018-08-08", "a-slug") }
        .to output.to_stdout
    end
  end

  describe "csv_from_living_in_europe" do
    it "outputs a report of subscriptions to living in Europe lists" do
      expect { Rake::Task["report:csv_from_living_in_europe"].invoke("2018-08-08") }
        .to output.to_stdout
    end
  end

  describe "csv_from_travel_advice_at" do
    it "outputs a report of subscriptions to travel advice lists on a date" do
      expect { Rake::Task["report:csv_from_travel_advice_at"].invoke("2018-08-08") }
        .to output.to_stdout
    end
  end

  describe "csv_from_travel_advice_at" do
    it "outputs a report of unpublishing between the specified dates" do
      expect { Rake::Task["report:unpublishing"].invoke("2018-08-08", "2018-08-09") }
        .to output.to_stdout
    end
  end
end
