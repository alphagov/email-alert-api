RSpec.describe "report" do
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

  describe "csv_from_living_in_europe" do
    it "outputs a report of subscriptions to living in Europe lists" do
      expect { Rake::Task["report:csv_from_living_in_europe"].invoke("2018-08-08") }
        .to output.to_stdout
    end
  end
end
