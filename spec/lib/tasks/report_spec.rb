require "rails_helper"

RSpec.describe "report" do
  describe "matched_content_changes" do
    it "outputs a CSV of matched content changes" do
      expect { Rake::Task["report:matched_content_changes"].invoke }
        .to output.to_stdout
    end
  end
end
