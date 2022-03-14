RSpec.describe Reports::SinglePageNotificationsReport do
  before do
    @single_page_notifications_sub_list = FactoryBot.create_list(:subscriber_list, 26, :for_single_page_subscription)
    @other_sub_list = FactoryBot.create(:subscriber_list)
  end

  describe "#call" do
    let(:report) { Reports::SinglePageNotificationsReport.new }

    it "the first line reports total active subscriptions for subscriber lists with a content_id" do
      expect(report.call[0]).to eq("There are 26 subscription lists with content_ids as of #{report.report_time}\n")
    end

    it "sorts active subscriptions, from most subscribed to least subscribed" do
      subscriber_counts = report.call[2..].map { |row| row.split("Has ").last.split(" Active").first.to_i }
      expect(subscriber_counts.first > subscriber_counts.last).to be true
    end

    it "reports on subscriber counts for individual subscriber lists with a content_id" do
      reported_list_titles = report.call[2..].map { |row| row.split("\n").first.split("Title: ").last }
      all_list_titles = @single_page_notifications_sub_list.map(&:title)
      expect(reported_list_titles - all_list_titles).to be_empty
    end

    it "does not report on subscriber lists without a content_id" do
      reported_list_titles = report.call[2..].map { |row| row.split("\n").first.split("Title: ").last }
      expect(reported_list_titles).not_to include(@other_sub_list.title)
    end

    it "limits output to top 25 subscriber lists by subscription count" do
      report_output = report.call

      expect(report_output[1]).to eq("Top 25 lists by active subscriber count are:\n")
      expect(report_output[2..].count).to eq(25)
    end

    context "when provided with a limit of 5" do
      let(:report) { Reports::SinglePageNotificationsReport.new(5) }

      it "limits output to top 5 subscriptions" do
        report_output = report.call

        expect(report_output[1]).to eq("Top 5 lists by active subscriber count are:\n")
        expect(report_output[2..].count).to eq(5)
      end
    end
  end
end
