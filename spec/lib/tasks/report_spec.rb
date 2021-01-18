RSpec.describe "report" do
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
end
