require "rails_helper"

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
end
